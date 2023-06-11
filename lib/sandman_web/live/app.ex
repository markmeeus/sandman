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
          <div id="document-container" class="h-full" style="overflow:scroll;">
            <div id="document-root">
              <SandmanWeb.LiveView.Document.render document={@document} code="ola code" />
            </div>
          </div>
          <div id="log-container" class="overscroll-contain" style="overflow:scroll; background-color: #E8E8E8">
            <SandmanWeb.LiveView.Log.render log="ola log" />
          </div>
        </div>
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
    #PubSub.subscribe(Sandman.PubSub, "document:#{doc_id}")
    {:ok, doc_pid} = Document.start_link(doc_id, "/Users/markmeeus/Documents/projects/github/sandman/doc/test.json")
    document = Document.get(doc_pid)
    socket = socket
    |> assign(:doc_pid, doc_pid)
    |> assign(:document, document)
    |> assign(:log, "")
    {:ok, socket}
  end
  def handle_event("code-changed", %{"blockId" => block_id, "value" => value}, socket) do
    # persist document here
    {:noreply, socket}
  end
end
