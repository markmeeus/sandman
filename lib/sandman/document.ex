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

  def init([doc_id, file_path]) do
    #TODO: load doc from file
    {:ok, file} = File.read(file_path)
    document = Jason.decode!(file)

    # assign id's (it's index basically) to every block
    document = update_in(document["blocks"], fn blocks ->
      blocks
      |> Enum.with_index()
      |> Enum.map(fn {block, id} -> Map.put(block, :id, id) end)
    end)

    PubSub.broadcast(Sandman.PubSub, "document:#{doc_id}", :document_loaded)
    {:ok, %{
      doc_id: doc_id,
      document: document
    }}
  end

  def handle_call(:get, _sender, state = %{document: document}), do: {:reply, document, state}
end
