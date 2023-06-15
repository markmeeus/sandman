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
        <div id="document-log-container" class="h-screen">
          <div id="document-container" style="overflow:scroll;" phx-hook="MaintainDimensions">
            <div id="document-root">
              <SandmanWeb.LiveView.Document.render document={@document.document} code="ola code" />
            </div>
          </div>
          <div class="gutter gutter-vertical" id="doc-log-gutter" phx-update="ignore"></div>
          <div id="log-container" class="overscroll-contain" phx-hook="MaintainDimensions" style="overflow:scroll; background-color: #E8E8E8">
            <SandmanWeb.LiveView.Log.render logs={@streams.logs} />
          </div>
        </div>
        <div class="gutter gutter-horizontal" id="doc-req-gutter" phx-update="ignore"></div>
        <div id="req-res-container" style="overflow:scroll;">
        <SandmanWeb.LiveView.RequestResponse.render tab="Request" sub_tab="Headers" req_res = {
          %{
            req: %{
              headers: "REQ headers",
              body: "REQ body"
            },
            res: %{
              headers: "RESP headers",
              body: "RESP body"
            },
          }
        }/>
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

  def handle_event("run-to-block", %{"block-id" => block_id}, socket = %{assigns: %{doc_pid: doc_pid}}) do
    # persist document here
    Document.run_to_block(doc_pid, block_id)
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

  def handle_info(:document_loaded, socket = %{assigns: %{doc_pid: doc_pid}}) do
    {:noreply, assign(socket, :document, Document.get(doc_pid))}
  end

  def handle_info(:document_changed, socket = %{assigns: %{doc_pid: doc_pid}}) do
    {:noreply, assign(socket, :document, Document.get(doc_pid))}
  end

  def handle_info({:log, text}, socket = %{assigns: %{doc_pid: doc_pid, log_count: log_count}}) do
    socket = socket
    |> assign(:log_count, log_count + 1)
    |> stream_insert(:logs, %{id: log_count, text: text})
    {:noreply, socket}
  end

end
