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

  def run_code(pid, state_id, new_state_id, response_tag, code) do
    GenServer.cast(pid, {:spawn_code, state_id, new_state_id, response_tag, code})
  end

  def call_function(pid, state_id, new_state_id, response_tag, function_path, args) do
    GenServer.cast(pid, {:call_function, state_id, new_state_id, response_tag, function_path, args})
  end
  def spawn_function(pid, state_id, new_state_id, response_tag, function_path, args) do
    GenServer.cast(pid, {:spawn_function, state_id, new_state_id, response_tag, function_path, args})
  end

  def init({document_pid, handlers}) do
    state = %{
      luerl_states: %{}, #every block has it's own state
      handlers: handlers,
      document_pid: document_pid
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

  #this is not used..., also not tested... needs luerl_states on error refactoring at the very least.
  def handle_cast(
        {:call_function, state_id, new_state_id, response_tag, function_path, args},
        state = %{luerl_states: luerl_states, document_pid: document_pid}
      ) do
    luerl_state = case {state_id, get_luerl_state(luerl_states, state_id, nil)}  do
        {nil, luerl_state} -> set_context(luerl_state, %{ block_id: new_state_id }) # nil always returns a new valid state
        {_, nil} -> :no_state_for_block # if asking state for a block, it should be there!
        {_, luerl_state} -> set_context(luerl_state, %{ block_id: new_state_id })
    end
    {response, luerl_states} =
      case luerl_state do
        :no_state_for_block -> {:no_state_for_block, luerl_states}
        _ ->
          case LuerlWrapper.call_function(function_path, args, luerl_state) do
            {:ok, [], luerl_state} ->
              {[], save_luerl_state(luerl_states, new_state_id, luerl_state)}

            {:ok, [response], luerl_state} ->
              {response, save_luerl_state(luerl_states, new_state_id, luerl_state)}
            # lua has multiple return values, only consuming first one for now
            {:ok, [response | _], luerl_state}  ->
              {response, save_luerl_state(luerl_states, new_state_id, luerl_state)}

            {:error, err, _, formatted} ->
              {{:error, err, formatted}, luerl_states}

          end
      end

    send(document_pid, {:lua_response, response_tag, response})
    {:noreply, %{state | luerl_states: luerl_states}}
  end

  # same as call, but runs in isolation and returns the result
  def handle_cast(
        {:spawn_function, state_id, new_state_id, response_tag, function_path, args},
        state = %{luerl_states: luerl_states, document_pid: document_pid}
      ) do
    luerl_state = case {state_id, get_luerl_state(luerl_states, state_id, nil)}  do
        {nil, luerl_state} -> set_context(luerl_state, %{ block_id: new_state_id }) # nil always returns a new valid state
        {_, nil} -> :no_state_for_block # if asking state for a block, it should be there!
        {_, luerl_state} -> set_context(luerl_state, %{ block_id: new_state_id })
    end

      case luerl_state do
        :no_state_for_block ->
          send(document_pid, {:lua_response, response_tag, :no_state_for_block})
        _ ->
          self_pid = self()
          spawn(fn ->
            case LuerlWrapper.call_function(function_path, args, luerl_state) do
              {:ok, [], luerl_state} ->
                send(self_pid, {:spawn_result, [], response_tag, :ok, new_state_id, luerl_state})

              {:ok, [response], luerl_state} ->
                send(self_pid, {:spawn_result, response, response_tag, :ok, new_state_id, luerl_state})
              # lua has multiple return values, only consuming first one for now
              {:ok, [response | _], luerl_state}  ->
                send(self_pid, {:spawn_result, response, response_tag, :ok, new_state_id, luerl_state})
              {:error, err, _, formatted} ->
                send(self_pid, {:spawn_result, {:error, err, formatted}, response_tag, :error, nil, nil})

            end
          end)
      end
      {:noreply, state}
  end

  def handle_cast({:spawn_code, state_id, new_state_id, response_tag, code},
        state = %{luerl_states: luerl_states, document_pid: document_pid, handlers: handlers}
      ) do
    luerl_state = case {state_id, get_luerl_state(luerl_states, state_id, handlers)}  do
        {nil, luerl_state} -> set_context(luerl_state, %{ block_id: new_state_id }) # nil always returns a new valid state
        {_, nil} -> :no_state_for_block # if asking state for a block, it should be there!
        {_, luerl_state} -> set_context(luerl_state, %{ block_id: new_state_id })
    end

      case luerl_state do
        :no_state_for_block ->
          send(document_pid, {:lua_response, response_tag, :no_state_for_block})
        _ ->
          self_pid = self()
          spawn(fn ->
            case LuerlWrapper.run_code(code, luerl_state) do
              {:ok, [], luerl_state} ->
                send(self_pid, {:spawn_result, [], response_tag, :ok, new_state_id, luerl_state})

              {:ok, [response], luerl_state} ->
                send(self_pid, {:spawn_result, response, response_tag, :ok, new_state_id, luerl_state})
              # lua has multiple return values, only consuming first one for now
              {:ok, [response | _], luerl_state}  ->
                send(self_pid, {:spawn_result, response, response_tag, :ok, new_state_id, luerl_state})
              {:error, err, _, formatted} ->
                send(self_pid, {:spawn_result, {:error, err, formatted}, response_tag, :error, nil, nil})

            end
          end)
      end
    {:noreply, state}
  end
  def handle_cast({:reset, state_ids}, state = %{luerl_states: luerl_states}) do
    new_states = Enum.reduce(state_ids, luerl_states, fn state_id, states ->
      Map.drop(states, [state_id])
    end)
    {:noreply, Map.put(state, :luerl_states, new_states) }
  end

  def handle_info({:spawn_result, response, response_tag, :ok, state_id, luerl_state},
    state = %{luerl_states: luerl_states, document_pid: document_pid}
  ) do
    send(document_pid, {:lua_response, response_tag, response})
    luerl_states = save_luerl_state(luerl_states, state_id, luerl_state)
    {:noreply, %{state | luerl_states: luerl_states}}
  end

  def handle_info({:spawn_result, response, response_tag, :error, _, _},
    state = %{document_pid: document_pid}
  ) do
    send(document_pid, {:lua_response, response_tag, response})
    {:noreply, state}
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
