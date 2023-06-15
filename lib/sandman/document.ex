defmodule Sandman.Document do

  alias Sandman.LuerlServer
  alias Phoenix.PubSub

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

  def init([doc_id, file_path]) do
    #TODO: load doc from file
    self_pid = self()
    {:ok, luerl_server_pid} = LuerlServer.start_link(self_pid, %{
      print: fn args, luerl_state ->
        {:ok, res} = GenServer.call(self_pid, {:handle_lua_call, :print, args})
        {res, luerl_state}
      end,
      # fetch: fn method, args, luerl_state ->
      #   HttpClient.fetch_handler(agent_id, method, args, luerl_state)
      # end,
      # json_decode: &Json.decode(agent_id, &1, &2),
      # json_encode: &Json.encode(agent_id, &1, &2),
    })
    {:ok, file} = File.read(file_path)
    document = Jason.decode!(file)
    log = "log from init"
    PubSub.broadcast(Sandman.PubSub, "document:#{doc_id}", :document_loaded)
    {:ok, %{
      doc_id: doc_id,
      document: document,
      file_path: file_path,
      log: log
    }}
  end

  def handle_call(:get, _sender, state = %{document: document, log: log}) do
    {:reply, %{document: document, log: log}, state}
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

  def handle_cast({:add_block, :after, after_block_id}, state  = %{document: document, doc_id: doc_id}) do
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
  defp write_file(document, %{file_path: file_path}) do
    :ok = File.write(file_path, Jason.encode!(document))
  end

  # luacallbacks
  def handle_call({:handle_lua_call, :print, arg}, _sender, state = %{document: document}) do
    formatted = arg
    |> Enum.map(&LuaMapper.to_printable/1)
    |> Enum.join(" ")
    # logs should be appended here and raise a doc changed event;
    log(state, formatted)
    # append
    {:reply, {:ok, [true]}, state}
  end
end
