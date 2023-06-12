defmodule Sandman.Document do

  use GenServer, restart: :transient

  alias Phoenix.PubSub

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
    IO.inspect("adding block")
    GenServer.cast(pid, {:add_block, :after, after_block})
  end

  def init([doc_id, file_path]) do
    #TODO: load doc from file
    {:ok, file} = File.read(file_path)
    document = Jason.decode!(file)

    PubSub.broadcast(Sandman.PubSub, "document:#{doc_id}", :document_loaded)
    {:ok, %{
      doc_id: doc_id,
      document: document
    }}
  end

  def handle_call(:get, _sender, state = %{document: document}), do: {:reply, document, state}

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
    IO.inspect({"new doc", document})
    {:noreply, state = %{state | document: document}}
  end
end
