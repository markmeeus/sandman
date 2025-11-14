defmodule Sandman.LuerlServer do

  alias Sandman.LuerlWrapper

  def start_link(document_pid, handlers) do
    GenServer.start_link(__MODULE__, {document_pid, handlers})
  end

  def stop(pid, stop_reason) do
    # Given the :transient option in the child spec, the GenServer will restart
    # if any reason other than `:normal` is given.
    GenServer.stop(pid, stop_reason)
  end

  def reset_states(pid, state_ids) do
    GenServer.cast(pid, {:reset, state_ids})
  end

  def run_code(pid, state_id, new_state_id, response_tag, code, delay_ms \\ 0) do
    GenServer.cast(pid, {:spawn_code, state_id, new_state_id, response_tag, code, delay_ms})
  end

  def spawn_function(pid, state_id, new_state_id, response_tag, function_path, args) do
    GenServer.cast(pid, {:spawn_function, state_id, new_state_id, response_tag, function_path, args})
  end

  def init({document_pid, handlers}) do
    state = %{
      luerl_states: %{}, #every block has it's own state
      handlers: handlers,
      document_pid: document_pid,
      running_workers: %{} # Track spawned PIDs per new_state_id: %{"block_id" => [pid, pid, ...]}
    }

    Process.flag(:max_heap_size, %{
      # 1GB, arbritrary .... maybe in settings sometime?
      size: 1024 * 1024 * 1024,
      kill: true
    })

    {:ok, state}
  end

  def handle_cast({:run_code, state_id, new_state_id, response_tag, code},
        state = %{luerl_states: luerl_states, document_pid: document_pid, handlers: handlers}
      ) do
    luerl_state = case {state_id, get_luerl_state(luerl_states, state_id, handlers)}  do
        {nil, luerl_state} -> set_context(luerl_state, %{ block_id: new_state_id }) # nil always returns a new valid state
        {_, nil} -> :no_state_for_block # if asking state for a block, it should be there!
        {_, luerl_state} -> set_context(luerl_state, %{ block_id: new_state_id })
    end

    {response, luerl_states} =
      case luerl_state do
        :no_state_for_block -> {:no_state_for_block, luerl_states}
        _ ->
          case LuerlWrapper.run_code(code, luerl_state) do
            {:ok, [], luerl_state} ->
              {[], save_luerl_state(luerl_states, new_state_id, luerl_state)}

            {:ok, [response], luerl_state} ->
              {LuerlWrapper.decode(response, luerl_state), save_luerl_state(luerl_states, new_state_id, luerl_state)}

            {:error, err, _, formatted} ->
              {{:error, err, formatted}, luerl_states}
          end
      end

    # luerl_state = LuerlWrapper.collect_garbage(luerl_state)

    # send lua return to document
    send(document_pid, {:lua_response, response_tag, response})
    {:noreply, %{state | luerl_states: luerl_states}}
  end

  def handle_cast(
        {:spawn_function, state_id, new_state_id, response_tag, function_path, args},
        state = %{luerl_states: luerl_states, document_pid: document_pid, running_workers: running_workers}
      ) do
    luerl_state = case {state_id, get_luerl_state(luerl_states, state_id, nil)}  do
        {nil, luerl_state} -> set_context(luerl_state, %{ block_id: new_state_id }) # nil always returns a new valid state
        {_, nil} -> :no_state_for_block # if asking state for a block, it should be there!
        {_, luerl_state} -> set_context(luerl_state, %{ block_id: new_state_id })
    end

      new_state = case luerl_state do
        :no_state_for_block ->
          send(document_pid, {:lua_response, response_tag, :no_state_for_block})
          state
        _ ->
          self_pid = self()
          pid = spawn_link(fn ->
            worker_pid = self()
            case LuerlWrapper.call_function(function_path, args, luerl_state) do
              {:ok, [], luerl_state} ->
                send(self_pid, {:spawn_result, worker_pid, [], response_tag, :ok, new_state_id, luerl_state})

              {:ok, [response], luerl_state} ->
                send(self_pid, {:spawn_result, worker_pid, response, response_tag, :ok, new_state_id, luerl_state})
              # lua has multiple return values, only consuming first one for now
              {:ok, [response | _], luerl_state}  ->
                send(self_pid, {:spawn_result, worker_pid, response, response_tag, :ok, new_state_id, luerl_state})
              {:error, err, _, formatted} ->
                send(self_pid, {:spawn_result, worker_pid, {:error, err, formatted}, response_tag, :error, nil, nil})

            end
          end)
          # Add pid to running_workers for this new_state_id
          new_running_workers = Map.update(running_workers, new_state_id, [pid], fn pids -> [pid | pids] end)
          %{state | running_workers: new_running_workers}
      end
      {:noreply, new_state}
  end

  # Handle spawn_code without delay parameter (backward compatibility)
  def handle_cast({:spawn_code, state_id, new_state_id, response_tag, code}, state) do
    handle_cast({:spawn_code, state_id, new_state_id, response_tag, code, 0}, state)
  end

  # Handle spawn_code with delay parameter
  def handle_cast({:spawn_code, state_id, new_state_id, response_tag, code, delay_ms},
        state = %{luerl_states: luerl_states, document_pid: document_pid, handlers: handlers, running_workers: running_workers}
      ) do
    luerl_state = case {state_id, get_luerl_state(luerl_states, state_id, handlers)}  do
        {nil, luerl_state} -> set_context(luerl_state, %{ block_id: new_state_id }) # nil always returns a new valid state
        {_, nil} -> :no_state_for_block # if asking state for a block, it should be there!
        {_, luerl_state} -> set_context(luerl_state, %{ block_id: new_state_id })
    end

      new_state = case luerl_state do
        :no_state_for_block ->
          send(document_pid, {:lua_response, response_tag, :no_state_for_block})
          state
        _ ->
          self_pid = self()
          pid = spawn_link(fn ->
            worker_pid = self()
            if delay_ms > 0, do: Process.sleep(delay_ms)
            case LuerlWrapper.run_code(code, luerl_state) do
              {:ok, [], luerl_state} ->
                send(self_pid, {:spawn_result, worker_pid, [], response_tag, :ok, new_state_id, luerl_state})

              {:ok, [response], luerl_state} ->
                send(self_pid, {:spawn_result, worker_pid, response, response_tag, :ok, new_state_id, luerl_state})
              # lua has multiple return values, only consuming first one for now
              {:ok, [response | _], luerl_state}  ->
                send(self_pid, {:spawn_result, worker_pid, response, response_tag, :ok, new_state_id, luerl_state})
              {:error, err, _, formatted} ->
                send(self_pid, {:spawn_result, worker_pid, {:error, err, formatted}, response_tag, :error, nil, nil})

            end
          end)
          # Add pid to running_workers for this new_state_id
          new_running_workers = Map.update(running_workers, new_state_id, [pid], fn pids -> [pid | pids] end)
          %{state | running_workers: new_running_workers}
      end
    {:noreply, new_state}
  end
  def handle_cast({:reset, state_ids}, state = %{luerl_states: luerl_states}) do
    new_states = Enum.reduce(state_ids, luerl_states, fn state_id, states ->
      Map.drop(states, [state_id])
    end)
    {:noreply, Map.put(state, :luerl_states, new_states) }
  end

  def handle_info({:spawn_result, worker_pid, response, response_tag, :ok, state_id, luerl_state},
    state = %{luerl_states: luerl_states, document_pid: document_pid, running_workers: running_workers}
  ) do
    send(document_pid, {:lua_response, response_tag, response})
    luerl_states = save_luerl_state(luerl_states, state_id, luerl_state)

    # Remove the completed worker PID from running_workers for this state_id
    new_running_workers = Map.update(running_workers, state_id, [], fn pids ->
      List.delete(pids, worker_pid)
    end)

    {:noreply, %{state | luerl_states: luerl_states, running_workers: new_running_workers}}
  end

  def handle_info({:spawn_result, worker_pid, response, response_tag, :error, state_id, _},
    state = %{document_pid: document_pid, running_workers: running_workers}
  ) do
    send(document_pid, {:lua_response, response_tag, response})

    # Remove the failed worker PID from running_workers if state_id is present
    new_running_workers = if state_id do
      Map.update(running_workers, state_id, [], fn pids ->
        List.delete(pids, worker_pid)
      end)
    else
      running_workers
    end

    {:noreply, %{state | running_workers: new_running_workers}}
  end

  def terminate(_reason, state) do
    # Force kill all running worker processes (e.g., Lua code in infinite loops)
    # Iterate through all state_ids and their associated PIDs
    Enum.each(state[:running_workers] || %{}, fn {_state_id, pids} ->
      Enum.each(pids, fn pid ->
        if Process.alive?(pid) do
          Process.exit(pid, :kill)
        end
      end)
    end)
    :ok
  end

  def get_luerl_state(_, nil, handlers), do: LuerlWrapper.init(handlers)
  def get_luerl_state(luerl_states, state_id, _), do: luerl_states[state_id]

  def save_luerl_state(luerl_states, nil, _), do: luerl_states
  def save_luerl_state(luerl_states, state_id, luerl_state) do
    Map.put(luerl_states, state_id, luerl_state)
  end

  defp set_context(luerl_state, context) do
    LuerlWrapper.set_context(luerl_state, context)
  end
end
