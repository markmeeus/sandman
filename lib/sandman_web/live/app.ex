defmodule SandmanWeb.LiveView.App do
  # In Phoenix v1.6+ apps, the line is typically: use MyAppWeb, :live_view
  use Phoenix.LiveView,
    container: {:div, class: "h-full"}

  alias Sandman.Document
  alias Phoenix.PubSub

  @spec render(any) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
      <div id="app-wrapper" class="flex flex-row" phx-hook="HomeHook">
        <div id="document-log-container" class="h-screen" phx-hook="MaintainWidth">
          <div id="document-container" style="overflow:scroll;" phx-hook="MaintainHeight">
            <div id="document-root">
              <SandmanWeb.LiveView.Document.render requests={@document.requests} document={@document.document} code="ola code" />
            </div>
          </div>
          <div class="gutter gutter-vertical" id="doc-log-gutter" phx-update="ignore"></div>
          <div id="log-container" class="overscroll-contain flex flex-col " phx-hook="MaintainHeight" style="background-color: #E8E8E8">
            <SandmanWeb.LiveView.Log.render logs={@streams.logs} />
          </div>
        </div>
        <div class="gutter gutter-horizontal" id="doc-req-gutter" phx-update="ignore"></div>
        <div id="req-res-container" class="h-screen" style="overflow:scroll;" phx-hook="MaintainWidth">
            <SandmanWeb.LiveView.RequestResponse.render tab={@tab} sub_tab="Headers" request_id = {@request_id} requests={@document.requests}/>
        </div>
      </div>
    """
  end

  def mount(_params, _session, socket) do
    # start_doc
    doc_id = UUID.uuid4()
    PubSub.subscribe(Sandman.PubSub, "document:#{doc_id}")
    {:ok, doc_pid} = Document.start_link(doc_id, "/Users/markmeeus/Documents/projects/github/sandman/doc/test.json")
    document= Document.get(doc_pid)
    socket = socket
    |> assign(:doc_pid, doc_pid)
    |> assign(:document, document)
    |> assign(:log_count, 0)
    |> assign(:tab, "Request")
    |> assign(:request_id, nil)
    |> stream(:logs, [])

    {:ok, socket}
  end


  def handle_event("code-changed", %{"blockId" => block_id, "value" => code}, socket = %{assigns: %{doc_pid: doc_pid}}) do
    Document.change_code(doc_pid, block_id, code)
    {:noreply, socket}
  end

  def handle_event("add-block", %{"block-id" => block_id}, socket = %{assigns: %{doc_pid: doc_pid}}) do
    Document.add_block(doc_pid, block_id)
    {:noreply, socket}
  end

  def handle_event("run-block", %{"block-id" => block_id}, socket = %{assigns: %{doc_pid: doc_pid}}) do
    Document.run_block(doc_pid, block_id)
    {:noreply, socket}
  end

  def handle_event("remove-block", %{"block-id" => block_id}, socket = %{assigns: %{doc_pid: doc_pid}}) do
    # persist document here
    Document.remove_block(doc_pid, block_id)
    {:noreply, socket}
  end

  def handle_event("update", %{"_target" => ["title"], "title" => title}, socket = %{assigns: %{doc_pid: doc_pid}}) do
    Document.update_title(doc_pid, title)
    {:noreply, socket}
  end

  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    # switching subtab to headers, better to keep separate state
    {:noreply, assign(socket, tab: tab)}
  end

  def handle_event("select-request", %{"block-id" => block_id, "request-index" => request_index}, socket) do
    {request_index, _} = Integer.parse(request_index)
    {:noreply, assign(socket, request_id: {block_id, request_index})}
  end

  def handle_event("clear-log", _, socket = %{assigns: %{log_count: log_count}}) do
    socket = socket
    |> assign(:log_count, log_count + 1)
    |> stream(:logs, [], reset: true)
    {:noreply, socket}
  end

  def handle_info(:document_loaded, socket = %{assigns: %{doc_pid: doc_pid}}) do
    {:noreply, assign(socket, :document, Document.get(doc_pid))}
  end

  def handle_info(:document_changed, socket = %{assigns: %{doc_pid: doc_pid}}) do
    {:noreply, assign(socket, :document, Document.get(doc_pid))}
  end

  def handle_info(:request_recorded, socket = %{assigns: %{doc_pid: doc_pid}}) do
    doc = Document.get(doc_pid)
    {:noreply, assign(socket, :document, doc)}
  end

  def handle_info({:log, log}, socket = %{assigns: %{doc_pid: doc_pid, log_count: log_count}}) do
    socket = socket
    |> assign(:log_count, log_count + 1)
    |> stream_insert(:logs, Map.put(log, :id, log_count))
    {:noreply, socket}
  end

end
