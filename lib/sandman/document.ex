defmodule Sandman.Document do

  alias Phoenix.PubSub
  alias Sandman.LuerlServer
  alias Sandman.LuaMapper
  alias SandMan.HttpClient

  use GenServer, restart: :transient

  import Sandman.Logger

  # FIle load/save dialog
  # :wx.set_env(Desktop.Env.wx_env())
    # file_dialog = GenServer.whereis(MainApp)
    # |> Desktop.Window.webview()
    # |> :wxFileDialog.new([style: 2]) # 2 is wxFD_SAVE ....

    # :wxFileDialog.showModal(file_dialog)
    # :filename.join(
    #   :wxFileDialog.getDirectory(file_dialog),
    #   :wxFileDialog.getFilename(file_dialog)
    # )
    # |> IO.inspect()

  def start_link(doc_id, file_path) do
    GenServer.start_link(__MODULE__, [doc_id, file_path])
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

  def update_title(pid, title) do
    GenServer.cast(pid, {:update_title, title})
  end

  def run_block(pid, block_id) do
    GenServer.cast(pid, {:run_block, block_id})
  end

  def run_to_block(pid, block_id) do
    GenServer.cast(pid, {:run_to_block, block_id})
  end

  # request id is %{block_id: block_id, index }
  def get_request_by_id(requests, {block_id, index}) do
    request = (requests[block_id] || []) |> Enum.at(index)
    request
  end

  def init([doc_id, file_path]) do
    #TODO: load doc from file
    self_pid = self()
    {:ok, luerl_server_pid} = LuerlServer.start_link(self_pid, %{
      print: fn args, luerl_state ->
        {:ok, res} = GenServer.call(self_pid, {:handle_lua_call, :print, args})
        {res, luerl_state}
      end,
      fetch: fn method, args, luerl_state ->
        # this is running in the luerl_server
        # TODO; refactor this so that req can be stored before request is being sent
        {result, luerl_state} = HttpClient.fetch_handler(doc_id, method, args, luerl_state)
        # send the result to the document
        GenServer.cast(self_pid, {:record_http_request, result})
        # return with lua script
        {result.lua_result, luerl_state}
      end,
      # json_decode: &Json.decode(agent_id, &1, &2),
      # json_encode: &Json.encode(agent_id, &1, &2),
    })
    {:ok, file} = File.read(file_path)
    document = Jason.decode!(file)
    PubSub.broadcast(Sandman.PubSub, "document:#{doc_id}", :document_loaded)
    {:ok, %{
      doc_id: doc_id,
      document: document,
      file_path: file_path,
      luerl_server_pid: luerl_server_pid,
      requests: %{},
      current_block_id: nil
    }}
  end

  def handle_call(:get, _sender, state = %{document: document, requests: requests}) do
    {:reply, %{document: document, requests: requests}, state}
  end

  def handle_cast({:add_block, :after, "-"}, state  = %{document: document, doc_id: doc_id}) do
    new_block = %{
      "type" => "lua",
      "code" => "",
      "id" => UUID.uuid4()
    }
    new_blocks = [new_block] ++ (document["blocks"] || [])
    document = Map.put(document, "blocks", new_blocks)
    PubSub.broadcast(Sandman.PubSub, "document:#{doc_id}", :document_changed)
    write_file(document, state)
    {:noreply, state = %{ state | document: document}}
  end

  def handle_cast({:add_block, :after, after_block_id}, state = %{document: document, doc_id: doc_id}) do
    new_block = %{
      "type" => "lua",
      "code" => "",
      "id" => UUID.uuid4()
    }
    new_blocks = Enum.reduce(document["blocks"], [], fn
      block = %{"id" => ^after_block_id}, acc -> acc ++ [block, new_block]
      block, acc -> acc ++ [block]
    end)
    document = Map.put(document, "blocks", new_blocks)
    PubSub.broadcast(Sandman.PubSub, "document:#{doc_id}", :document_changed)
    write_file(document, state)
    {:noreply, state = %{ state | document: document}}
  end

  def handle_cast({:record_http_request, req_res}, state = %{doc_id: doc_id, requests: requests, current_block_id: block_id}) do
    new_state = update_in(state.requests[block_id], fn val -> val ++ [req_res] end)
    #new_state = Map.put(state, :requests, requests ++ [req_res])
    PubSub.broadcast(Sandman.PubSub, "document:#{doc_id}", :request_recorded)
    {:noreply, new_state}
  end

  def handle_cast({:remove_block, block_id}, state  = %{document: document, doc_id: doc_id}) do
    new_blocks = Enum.filter(document["blocks"], & &1["id"] != block_id)
    document = Map.put(document, "blocks", new_blocks)
    write_file(document, state)
    PubSub.broadcast(Sandman.PubSub, "document:#{doc_id}", :document_changed)
    {:noreply, state = %{ state | document: document}}
  end

  def handle_cast({:change_code, block_id, code}, state = %{document: document}) do
    new_blocks = Enum.map(document["blocks"], fn
      block = %{"id" => ^block_id} -> Map.put(block, "code", code)
      block -> block
    end)
    document = Map.put(document, "blocks", new_blocks)
    write_file(document, state)
    {:noreply, state = %{ state | document: document}}
  end

  def handle_cast({:update_title, title}, state = %{document: document}) do
    document = Map.put(document, :title, title)
    write_file(document, state)
    {:noreply, state = %{ state | document: document}}
  end

  def handle_cast({:run_block, block_id}, state = %{document: document, luerl_server_pid: luerl_server_pid}) do
    block = Enum.find(document["blocks"], & &1["id"] == block_id)
    LuerlServer.run_code(luerl_server_pid, {:run_block}, block["code"])

    state = put_in(state.requests[block_id], [])
    state = put_in(state.current_block_id, block_id)

    {:noreply, state}
  end

  def handle_cast({:run_to_block, block_id}, state = %{document: document, luerl_server_pid: luerl_server_pid}) do
    Enum.each(document["blocks"], fn block ->
      # TODO this is a cast, so we need to send the tail with the response tag?
      # or maybe only the block id's to run?
      # currently it will run all blocks in correct order because the mailbox is in order
      # but it should actually stop processing if a single block fails
      LuerlServer.run_code(luerl_server_pid, {:run_to_block, block_id, block["id"] }, block["code"])
    end)
    {:noreply, state}
  end

  def handle_info({:lua_response, {:run_to_block, to_block_id, result_for_block_id}, response}, state = %{doc_id: doc_id}) do
    case response do
      {:error, err, formatted} ->
        log(doc_id, "Error: " <> formatted)
      _ -> nil
    end
    {:noreply, state}
  end

  def handle_info({:lua_response, {:run_block}, response}, state = %{doc_id: doc_id}) do
    case response do
      {:error, err, formatted} ->
        log(doc_id, "Error: " <> formatted)
      _ -> nil
    end
    {:noreply, put_in(state.current_block_id, nil)}
  end

  defp write_file(document, %{file_path: file_path}) do
    :ok = File.write(file_path, Jason.encode!(document))
  end

  # luacallbacks
  def handle_call({:handle_lua_call, :print, arg}, _sender, state = %{document: document, doc_id: doc_id}) do
    formatted = arg
    |> Enum.map(&LuaMapper.to_printable/1)
    |> Enum.join(" ")
    # logs should be appended here and raise a doc changed event;
    log(doc_id, formatted)
    # append
    {:reply, {:ok, [true]}, state}
  end
end
