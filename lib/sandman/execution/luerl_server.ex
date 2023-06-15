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

  def run_code(pid, response_tag, code) do
    GenServer.cast(pid, {:run_code, response_tag, code})
  end

  def call_function(pid, response_tag, function_path, args) do
    GenServer.cast(pid, {:call_function, response_tag, function_path, args})
  end

  @impl true
  def init({document_pid, handlers}) do
    luerl_state = LuerlWrapper.init(handlers)
    state = %{
      luerl_state: luerl_state,
      document_pid: document_pid
    }

    Process.flag(:max_heap_size, %{
      # 100MB, arbritrary .... maybe in settings sometime?
      size: 10 * 1024 * 1024,
      kill: true
    })

    {:ok, state}
  end

  @impl true

  def handle_cast({:run_code, response_tag, code},
        state = %{luerl_state: luerl_state, document_pid: document_pid}
      ) do

    {response, luerl_state} =
      case LuerlWrapper.run_code(code, luerl_state) do
        {:ok, [], luerl_state} ->
          {[], luerl_state}

        {:ok, [response], luerl_state} ->
          {LuerlWrapper.decode(response, luerl_state), luerl_state}

        {:error, err, _, formatted} ->
          {{:error, err, formatted}, luerl_state}
      end

    # luerl_state = LuerlWrapper.collect_garbage(luerl_state)
    IO.inspect({"sending, resp", response})
    # send lua return to document
    send(document_pid, {:lua_response, response_tag, response})
    {:noreply, %{state | luerl_state: luerl_state}, :hibernate}
  end

  def handle_cast(
        {:call_function, response_tag, function_path, args},
        state = %{luerl_state: luerl_state, document_pid: document_pid}
      ) do
    IO.inspect({"calling function:", function_path})

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

    #luerl_state = LuerlWrapper.collect_garbage(luerl_state)

    # IO.inspect(
    #   {"state to binary took:",
    #    :timer.tc(fn ->
    #      IO.inspect({"luerl_state to binary:", byte_size(:erlang.term_to_binary(luerl_state))})
    #      :ok
    #    end)}
    # )

    send(document_pid, {:lua_response, response_tag, response})
    {:noreply, %{state | luerl_state: luerl_state}, :hibernate}
  end

  defp via_tuple(document_id),
    do: {:via, Registry, {@registry, document_id}}
end
