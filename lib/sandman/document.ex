defmodule Sandman.Document do

  alias Phoenix.Endpoint.Cowboy2Adapter
  alias Sandman.LuerlWrapper
  alias Phoenix.PubSub
  alias Sandman.LuerlServer
  alias Sandman.LuaMapper
  alias Sandman.HttpClient
  alias Sandman.Encoders.{Json, Base64}
  alias Sandman.LuaSupport.Jwt
  alias Sandman.DocumentEncoder
  alias Sandman.LuaSupport
  alias Sandman.Http.CowboyManager
  alias Sandman.DocumentHandlers

  use GenServer, restart: :transient

  import Sandman.Logger

  @write_interval 5000

  def start_link(doc_id, file_path, block_id_fn \\ fn _ -> UUID.uuid4() end ) do
    GenServer.start_link(__MODULE__, [doc_id, file_path, block_id_fn])
  end

  def get(pid) do
    GenServer.call(pid, :get)
  end

  def add_block(pid, after_block) do
    GenServer.cast(pid, {:add_block, :after, after_block})
  end

  def remove_block(pid, block_id) do
    GenServer.cast(pid, {:remove_block, block_id})
  end

  def change_code(pid, block_id, code) do
    GenServer.cast(pid, {:change_code, block_id, code})
  end


  def run_block(pid, block_id, context \\ %{}) do
    GenServer.cast(pid, {:run_block, block_id, context})
  end

  def run_all_blocks(pid) do
    GenServer.cast(pid, :run_all_blocks)
  end

  def update_block_state(pid, block_id, new_state) do
    GenServer.cast(pid, {:update_block_state, block_id, new_state})
  end

  def get_block_state(pid, block_id) do
    GenServer.call(pid, {:get_block_state, block_id})
  end

  def get_request_by_id(pid, {block_id, index}) when is_pid(pid) do
    GenServer.call(pid, {:get_request_by_id, {block_id, index}})
  end

  # request id is %{block_id: block_id, index }
  def get_request_by_id(requests, {block_id, index}) do
    request = (requests[block_id] || []) |> Enum.at(index)
    request
  end

  def handle_server_request(pid, server_id, request) do
    GenServer.cast(pid, {:handle_server_request, self(), server_id, request})
    receive do
      {:http_response, response} ->
        response
      after 60_000 ->
        %{ status: 504, body: "Request timeout", headers: %{"content-type" => "text/text" } }
    end
  end

  def init([doc_id, file_path, doc_id_fn]) do
    self_pid = self()
    handlers = DocumentHandlers.build_handlers(self_pid, doc_id)
    {:ok, luerl_server_pid} = LuerlServer.start_link(self_pid, handlers)
    File.touch!(file_path, :erlang.universaltime())
    {:ok, file} = File.read(file_path)
    document = DocumentEncoder.decode(file, doc_id_fn)
    PubSub.broadcast(Sandman.PubSub, "document:#{doc_id}", :document_loaded)
    {:ok, %{
      doc_id: doc_id,
      document: document,
      file_path: file_path,
      luerl_server_pid: luerl_server_pid,
      requests: %{},
      servers: %{},
      current_block_id: nil,
      current_block_context: %{},
      run_queue: [],
      shared: %{},
    }}
  end

  def handle_call(:get, _sender, state = %{document: document, requests: requests}) do
    {:reply, %{document: document, requests: requests}, state}
  end

  def handle_call({:get_request_by_id, {block_id, index}}, _, state = %{requests: requests}) do
    {:reply, get_request_by_id(requests, {block_id, index}), state}
  end

  def handle_call({:get_block_state, block_id}, _, state = %{document: document}) do
    block = Enum.find(document.blocks, & &1[:id] == block_id)
    block_state = case block do
      nil -> nil
      block -> Map.get(block, :state, :empty)
    end
    {:reply, block_state, state}
  end

  # luacallbacks
  def handle_call({:handle_lua_call, :print, arg}, _sender, state = %{doc_id: doc_id}) do
    formatted = arg
    |> Enum.map(&LuaMapper.to_printable/1)
    |> Enum.join(" ")
    # logs should be appended here and raise a doc changed event;
    log(doc_id, formatted)
    # append
    {:reply, {:ok, [true]}, state}
  end
  def handle_call({:handle_lua_call, :start_server, [port]}, _sender, state) do
    id =  UUID.uuid4()
    :ok = CowboyManager.connect(port, id)
    server = %{
      id: id,
      routes: [],
      block_id: state.current_block_id
    }
    new_state = %{state | servers: Map.put(state.servers, server.id, server)}
    {:reply, {:ok, [server.id]}, new_state}

  end
  def handle_call({:handle_lua_call, :add_route, [method, server_id, path, func = {:funref, _, _}], call_info}, _sender, state) do
    route = %{
      method: method,
      path: path,
      func: func,
      block_id: state.current_block_id,
      origin_call_info: call_info
    }
    #TODO: dont prepare all routes all the time
    new_routes = Sandman.Http.Server.prepare_routes(state.servers[server_id].routes ++ [route])
    new_state = put_in(state.servers[server_id].routes, new_routes)

    {:reply, {:ok, [true]}, new_state}
  end
  def handle_call({:handle_lua_call, :add_route, _args, _call_info}, _sender, state = %{doc_id: doc_id}) do
      message = "Error adding routes, invalid arguments, expecting server, path and handler"
      {:reply, {:error , message}, state}
  end
  def handle_call({:handle_lua_call, :document_set, [key, value]}, _sender, state = %{shared: shared}) do
    shared = Map.put(shared, key, value)
    new_state = put_in(state.shared, shared)
    IO.inspect({"new state", new_state})
    {:reply, {:ok, [true]}, new_state}
  end
  def handle_call({:handle_lua_call, :document_get, [key]}, _sender, state = %{shared: shared}) do
    IO.inspect({"shared", key, shared})
    {:reply, {:ok, Map.get(shared, key, nil)}, state}
  end
  def handle_cast({:handle_server_request, replyto_pid, server_id, request}, state = %{doc_id: doc_id, servers: servers}) do
    server = Map.get(servers, server_id)
    res = Sandman.Http.Server.handle_request(state.doc_id, state.luerl_server_pid, server.routes, {replyto_pid, request})

    if(res == :not_found) do
      log(doc_id, "#{Enum.join(request.path_info,"/")} => 404 Not Found")
      send(replyto_pid, {:http_response, %{status: 404, body: "Not Found", headers: %{"content-type" => "text/text" }}})
    end

    {:noreply, state}
  end

  def handle_cast({:add_block, :after, "-"}, state  = %{document: document, doc_id: doc_id}) do
    new_block = %{
      type: "lua",
      code: "",
      id: UUID.uuid4(),
      state: :empty
    }
    new_blocks = [new_block] ++ (document.blocks || [])
    document = Map.put(document, :blocks, new_blocks)
    PubSub.broadcast(Sandman.PubSub, "document:#{doc_id}", :document_changed)
    write_file(state)
    {:noreply, %{ state | document: document}}
  end

  def handle_cast({:add_block, :after, after_block_id}, state = %{document: document, doc_id: doc_id}) do
    new_block = %{
      type: "lua",
      code: "",
      id: UUID.uuid4(),
      state: :empty
    }
    new_blocks = Enum.reduce(document.blocks, [], fn
      block = %{id: ^after_block_id}, acc -> acc ++ [block, new_block]
      block, acc -> acc ++ [block]
    end)
    document = Map.put(document, :blocks, new_blocks)
    PubSub.broadcast(Sandman.PubSub, "document:#{doc_id}", :document_changed)
    write_file(state)
    {:noreply, %{ state | document: document}}
  end

  def handle_cast({:record_http_request, req_res, call_info, block_id}, state = %{doc_id: doc_id, current_block_id: current_block_id}) do
    req_res = Map.put(req_res, :call_info, call_info)
    block_id = call_info.block_id
    new_state = update_in(state.requests[block_id], fn val -> (val || []) ++ [req_res] end)
    #new_state = Map.put(state, :requests, requests ++ [req_res])
    PubSub.broadcast(Sandman.PubSub, "document:#{doc_id}", {:request_recorded, block_id})
    {:noreply, new_state}
  end

  def handle_cast({:remove_block, block_id}, state  = %{document: document, doc_id: doc_id}) do
    new_blocks = Enum.filter(document.blocks, & &1[:id] != block_id)
    document = Map.put(document, :blocks, new_blocks)
    write_file(state)
    PubSub.broadcast(Sandman.PubSub, "document:#{doc_id}", :document_changed)
    {:noreply, %{ state | document: document}}
  end

  def handle_cast({:change_code, block_id, code}, state = %{document: document}) do
    new_blocks = Enum.map(document.blocks, fn
      block = %{id: ^block_id} -> Map.put(block, :code, code)
      block -> block
    end)
    document = Map.put(document, :blocks, new_blocks)
    write_file(state)
    {:noreply, %{ state | document: document}}
  end

  def handle_cast({:update_block_state, block_id, new_state}, state = %{document: document, doc_id: doc_id}) do
    new_blocks = Enum.map(document.blocks, fn
      block = %{id: ^block_id} -> Map.put(block, :state, new_state)
      block -> block
    end)
    document = Map.put(document, :blocks, new_blocks)
    PubSub.broadcast(Sandman.PubSub, "document:#{doc_id}", {:block_state_changed, block_id, new_state})
    {:noreply, %{ state | document: document}}
  end


  def handle_cast({:run_block, block_id}, state ) do
    {:noreply, start_block(block_id, %{}, state)}
  end

  def handle_cast({:run_block, block_id, context}, state ) do
    {:noreply, start_block(block_id, context, state)}
  end

  def handle_cast(:run_all_blocks, state = %{document: document}) do
    # only run lua blocks
    state = case document.blocks |> Enum.filter(& &1.type == "lua") do
      [] -> state
      [first | run_queue ] ->
        state = Map.put(state, :run_queue, run_queue)
        start_block(first.id, %{}, state)
    end
    {:noreply, state}
  end

  def handle_info(:write_file, state = %{document: document, file_path: file_path}) do
    :ok = File.write(file_path, DocumentEncoder.encode(document))
    {:noreply, state}
  end
  def handle_info({:server_connected, port}, state = %{doc_id: doc_id}) do
    log(doc_id, "started listening at #{port}")
    {:noreply, state}
  end
  def handle_info({:server_disconnected, port}, state = %{doc_id: doc_id}) do
    log(doc_id, "stopped listening at #{port}")
    {:noreply, state}
  end
  def handle_info({:lua_response, {:run_block}, response}, state = %{doc_id: doc_id, current_block_id: current_block_id}) do
    context = Map.get(state, :current_block_context, %{})
    # Update block state based on execution result
    case response do
      {:error, _err, formatted} ->
        if current_block_id do
          update_block_state(self(), current_block_id, :errored)
        end
        log(doc_id, "Error: " <> formatted)
      :no_state_for_block ->
        if current_block_id do
          update_block_state(self(), current_block_id, :errored)
        end
        log(doc_id, "This block cannot be run right now. Did you run the previous block?")
      _ ->
        if current_block_id do
          update_block_state(self(), current_block_id, :executed)
          # Emit block-executed event with context
          PubSub.broadcast(Sandman.PubSub, "document:#{doc_id}", {:block_executed, current_block_id, context})
        end
    end

    state = put_in(state.current_block_id, nil)
    state = put_in(state.current_block_context, %{})
    state = case response do
      {:error, _err, _formatted} ->
        put_in(state.run_queue, [])
      :no_state_for_block ->
        put_in(state.run_queue, [])
      _ ->
        # in dit geval starten we een niewe
        start_next_queued_block(state)
    end
    {:noreply, state}
  end

  def handle_info({:lua_response, {:http_response, replyto_pid, route, request, block_id}, response}, state = %{doc_id: doc_id}) do
    case response do
      {:error, _err, formatted} ->
        log(doc_id, "Error executing route: #{route.path}\n" <> formatted)
        send(replyto_pid, {:http_response, %{
          body: "Error",
          status: 500,
          headers: %{"content-type" => "text/text" }
        }})
      _ ->
        response = Sandman.Http.Server.map_lua_response(doc_id, response)
        req_res = Sandman.Http.Server.build_req_res(request, response)
        call_info = route.origin_call_info

        GenServer.cast(self(), {:record_http_request, req_res, call_info, block_id})
        send(replyto_pid, {:http_response, response})
    end
    {:noreply, state}
  end

  defp write_file(%{file_path: file_path}) do
    self_pid = self()
    Debouncer.immediate(file_path, fn ->
      send(self_pid, :write_file)
    end, @write_interval)
  end

  defp clean_servers_and_routes(servers, block_id) do
    Enum.reduce(servers, %{}, fn
      {_, %{block_id: ^block_id, id: id}}, servers ->
        # let's disconnect from this server
        CowboyManager.disconnect(id)
        servers
      {_id, server}, servers ->
        # keeping this server, but only keep routes that are not part of this block
        new_routes = Enum.filter(server.routes, fn route -> route.block_id != block_id end)
        new_server = Map.put(server, :routes, new_routes)
        Map.put(servers, server.id, new_server)
    end)
  end

  defp start_next_queued_block(state = %{run_queue: []}), do: state
  defp start_next_queued_block(state = %{run_queue: [next | rest_queue]}) do
    state = Map.put(state, :run_queue, rest_queue)
    start_block(next.id, %{}, state)
  end

  defp start_block(block_id, context, state = %{document: document, doc_id: doc_id, luerl_server_pid: luerl_server_pid}) do
    block = Enum.find(document.blocks, & &1[:id] == block_id)

    # If block is not found, return the state unchanged
    if is_nil(block) do
      state
    else
      {prev_blocks, next_blocks} =  document.blocks
        |> Enum.split_while(fn bl -> bl.id != block.id end)

    last_block_id = prev_blocks
      |> Enum.reverse()
      |> Enum.find(& &1.type == "lua")
      |> case do
        nil -> nil
        block -> block.id
      end
    blocks_to_reset = case next_blocks do
      [_] -> [block]
      [_ | next_blocks] -> next_blocks ++ [block]
    end
    |> Enum.map(& &1.id)

    # Reset block states to :empty for all blocks that will be reset
    Enum.each(blocks_to_reset, fn block_id ->
      update_block_state(self(), block_id, :empty)
    end)

    clean_servers = Enum.reduce(blocks_to_reset, state.servers, fn block_id, servers ->
      clean_servers_and_routes(servers, block_id)
    end)
    state = put_in(state.servers, clean_servers)
    LuerlServer.reset_states(luerl_server_pid, blocks_to_reset)

    # Set block state to :running before execution
    update_block_state(self(), block.id, :running)
    # pass 500ms delay, so the ui has a chance to view the state change
    LuerlServer.run_code(luerl_server_pid, last_block_id, block.id, {:run_block}, block.code, 50)

    state = put_in(state.requests[block_id], [])
    state = put_in(state.current_block_id, block_id)
    state = put_in(state.current_block_context, context)
    # using request recorded, since all requests are gone now
    # todo: refactor this
    PubSub.broadcast(Sandman.PubSub, "document:#{doc_id}", {:request_recorded, block.id})
    state
    end
  end
end
