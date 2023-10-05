defmodule Sandman.Http.CowboyManager do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    Process.flag(:trap_exit, true)
    {:ok, %{
      port_infos: %{},
    }}
  end

  def connect(port, id) do
    GenServer.cast(__MODULE__, {:connect, self(), port, id})
  end

  def disconnect(id) do
    GenServer.cast(__MODULE__, {:disconnect, self(), id})
  end

  def handle_server_request(port, request) do
    client_info = GenServer.call(__MODULE__, {:get_document_info, port})

    case client_info  do
      nil ->
        %{
          status: 503,
          body: "Service Not Available",
          headers: %{"content-type" => "text/text" } }
      %{client_pid: pid, id: id} ->
        Sandman.Document.handle_server_request(pid, id, request)
    end

  end

  def handle_cast({:connect, client_pid, port, id}, state) do
    Process.link(client_pid)
    client = %{client_pid: client_pid, id: id}
    state = update_in(state.port_infos[port], fn
      nil ->
        ref = String.to_atom(id)
        {:ok, _} = Plug.Cowboy.http(Sandman.UserPlug, {port} , port: port, ref: ref)
        %{
          port: port,
          clients: [client],
          ref: ref
        }
      port_info ->
        # push client in front
        update_in(port_info[port], &[client | &1])
    end)
    {:noreply, state |> IO.inspect}
  end

  def handle_cast({:disconnect, client_pid, id}, state) do
    Process.unlink(client_pid)
    client = %{client_pid: client_pid, id: id}
    new_port_infos = Enum.reduce(state.port_infos, %{}, fn {port, port_info}, acc ->
      clients = Enum.filter(port_info.clients, fn client ->
        client != client
      end)
      |> case do
        [] ->
          # this cowboy may die
          :ok = Plug.Cowboy.shutdown(port_info.ref)
          # no need to keep it in the server list
          acc
        _ -> Map.put(acc, port, port_info)
       end
    end)
    {:noreply, Map.put(state, :port_infos, new_port_infos) |> IO.inspect}
  end

  def handle_call({:get_document_info, port}, _sender, state) do
    pid = case state.port_infos[port] do
      %{clients: [client_info | _]} ->
        client_info
      _ ->
        nil
    end

    {:reply, pid, state}
  end

  def handle_info({:EXIT, pid, _}, state) do
    # remove all clients for this process
    new_port_infos = Enum.reduce(state.port_infos, %{}, fn {port, port_info}, acc ->
      clients = Enum.filter(port_info.clients, fn client ->
        client.client_pid != pid
      end)
      |> case do
        [] ->
          # this cowboy may die
          :ok = Plug.Cowboy.shutdown(port_info.ref)
          # no need to keep it in the server list
          acc
        _ -> Map.put(acc, port, port_info)
       end
    end)
    {:noreply, Map.put(state, :port_infos, new_port_infos) |> IO.inspect}
  end
end
