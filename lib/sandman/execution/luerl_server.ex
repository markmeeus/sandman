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
    GenServer.cast(pid, {:run_code, state_id, new_state_id, response_tag, code})
  end

  def call_function(pid, state_id, new_state_id, response_tag, function_path, args) do
    GenServer.cast(pid, {:call_function, state_id, new_state_id, response_tag, function_path, args})
  end

  @impl true
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

  @impl true

  def handle_cast({:run_code, state_id, new_state_id, response_tag, code},
        state = %{luerl_states: luerl_states, document_pid: document_pid, handlers: handlers}
      ) do
    luerl_state = case {state_id, get_luerl_state(luerl_states, state_id, handlers)}  do
        {nil, luerl_state} -> luerl_state # nil always returns a new valid state
        {_, nil} -> :no_state_for_block # if asking state for a block, it should be there!
        {_, luerl_state} -> luerl_state
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
    {:noreply, %{state | luerl_states: luerl_states}, :hibernate}
  end

  #this is not used..., also not tested... needs luerl_states on error refactoring at the very least.
  def handle_cast(
        {:call_function, state_id, new_state_id, response_tag, function_path, args, handlers: handlers},
        state = %{luerl_states: luerl_states, document_pid: document_pid}
      ) do
    luerl_state = get_luerl_state(luerl_states, state_id, handlers)
    {response, luerl_state} =
      case LuerlWrapper.call_function(function_path, args, luerl_state) do
        {:ok, [], luerl_state} ->
          {[], luerl_state}

        {:ok, [response], luerl_state} ->
          {response, luerl_state}
        # lua has multiple return values, only consuming first one for now
        {:ok, [response | _], luerl_state}  ->
          {response, luerl_state}

        {:error, err, _, formatted} ->
          {{:error, err, formatted}, luerl_state}

      end

    send(document_pid, {:lua_response, response_tag, response})
    luerl_states = save_luerl_state(luerl_states, new_state_id, luerl_state)
    {:noreply, %{state | luerl_states: luerl_states}, :hibernate}
  end

  def handle_cast({:reset, state_ids}, state = %{luerl_states: luerl_states}) do
    new_states = Enum.reduce(state_ids, luerl_states, fn state_id, states ->
      Map.drop(states, [state_id])
    end)
    {:noreply, Map.put(state, :luerl_states, new_states) }
  end

  def get_luerl_state(luerl_states, nil, handlers), do: LuerlWrapper.init(handlers)
  def get_luerl_state(luerl_states, state_id, _), do: luerl_state = luerl_states[state_id]

  def save_luerl_state(luerl_states, nil, _), do: luerl_states
  def save_luerl_state(luerl_states, state_id, luerl_state) do
    Map.put(luerl_states, state_id, luerl_state)
  end

  defp via_tuple(document_id),
    do: {:via, Registry, {@registry, document_id}}
end
