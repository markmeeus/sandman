defmodule SandmanWeb.LiveView.Runner do
  # In Phoenix v1.6+ apps, the line is typically: use MyAppWeb, :live_view
  use Phoenix.LiveView,
    container: {:div, class: "h-full"}

  alias Sandman.Document
  alias Phoenix.PubSub

  @spec render(any) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
      <div id="sandman-log" phx-hook="RunnerHook" class="text-black text-xs">
        <div id="log-bar" class="space-x-1 flex flex-row-reverse" style="background-color:#EEE">
          <button class="mr-1" >clear</button>
          <div class="grow">Log</div>
        </div>
        <div id="log-wrapper" class="font-mono p-2">
          <%= @log %>
        </div>
      </div>
    """
  end

  def mount(_params, _session, socket) do
    # start_doc
    doc_id = UUID.uuid4()
    PubSub.subscribe(Sandman.PubSub, "document:#{doc_id}")
    {:ok, doc_pid} = Document.start_link(doc_id, "/Users/markmeeus/Documents/projects/github/sandman/doc/test.json")

    socket = socket
    |> assign(:doc_pid, doc_pid)
    |> assign(:log, "")
    {:ok, socket}
  end

  def handle_event("run-block", params, socket) do
    # TODO: run block on document
    {:noreply, assign(socket, :log, socket.assigns.log <> inspect(params))}
  end

  def handle_info(:document_loaded, socket = %{assigns: %{doc_pid: doc_pid}}) do
    document = Document.get(doc_pid)

    socket =  socket
    |> push_event("document_loaded", document)
    |> assign(:log, "document loaded")

    {:noreply, socket}
  end
end
