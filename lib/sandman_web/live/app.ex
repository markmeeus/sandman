defmodule SandmanWeb.LiveView.App do
  # In Phoenix v1.6+ apps, the line is typically: use MyAppWeb, :live_view
  use Phoenix.LiveView,
    container: {:div, class: "h-full"}

  alias Sandman.Document
  alias Sandman.FileAccess
  alias SandmanWeb.UpdateBar
  alias Phoenix.PubSub

  @spec render(any) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    if(assigns[:doc_pid]) do
      render_app(assigns)
    else
      render_select_file(assigns)
    end
  end

  def render_app(assigns) do
    ~H"""
      <%= live_render(@socket, UpdateBar, id: "update_bar") %>
      <div id="app-wrapper" class="flex flex-row" phx-hook="HomeHook">

          <div id="document-container" style="overflow:scroll;" class="h-screen">
            <div id="document-root">
              <SandmanWeb.LiveView.Document.render doc_pid={@doc_pid} open_requests={@open_requests} requests={@document.requests} document={@document.document} code="ola code" />
            </div>
          </div>

        <div class="gutter gutter-horizontal" id="doc-req-gutter" phx-update="ignore"></div>

        <div id="req-res-container" class="h-screen flex-grow" style="overflow:scroll;" phx-hook="MaintainWidth">
          <div style="background-color:#1E1E1E;">
            <div class="">
              <nav class="flex space-x-4" aria-label="Tabs">
                <!-- Current: "bg-gray-100 text-gray-700", Default: "text-gray-500 hover:text-gray-700" -->
                <a href="#" class={"#{tab_colors(@main_left_tab, :req_res)} px-3 py-2 text-sm font-medium"} phx-click="change-main-left-tab" phx-value-tab-id="req_res">Request Info</a>
                <a href="#" class={"#{tab_colors(@main_left_tab, :logs)} px-3 py-2 text-sm font-medium"}  phx-click="change-main-left-tab" phx-value-tab-id="logs">Logs</a>
                <%!-- <a href="#" class={"#{tab_colors(@main_left_tab, :docs)}  px-3 py-2 text-sm font-medium"}  phx-click="change-main-left-tab" phx-value-tab-id="docs">Docs</a> --%>
              </nav>
            </div>
          </div>
            <div class={"pt-2 h-full #{tab_visibility(@main_left_tab, :req_res)}"}>
              <SandmanWeb.LiveView.RequestResponse.render
                doc_pid={@doc_pid}
                tab={@tab}
                sub_tab="Headers"
                request_id = {@request_id}
                requests={@document.requests}
                show_raw_req_body={@show_raw_req_body}
                show_raw_res_body={@show_raw_res_body}
                />
            </div>
            <div class={"pt-1 px-1 h-full #{tab_visibility(@main_left_tab, :logs)}"} >
              <SandmanWeb.LiveView.Log.render logs={@streams.logs} />
            </div>
        </div>
      </div>
    """
  end

  def render_select_file(assigns) do
    Sandman.NewOrOpen.render(assigns)
  end

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_event("open_file", _, socket) do
    {:noreply, start_document(:open, socket)}
  end

  def handle_event("new_file", _, socket) do
    {:noreply, start_document(:new, socket)}
  end

  defp start_document(mode, socket) do
        # start_doc
    doc_id = UUID.uuid4()
    PubSub.subscribe(Sandman.PubSub, "document:#{doc_id}")

    case FileAccess.select_file(mode) do
      file_name when is_bitstring(file_name) ->
        {:ok, doc_pid} = Document.start_link(doc_id, file_name)
        document= Document.get(doc_pid)
        socket
        |> assign(:doc_pid, doc_pid)
        |> assign(:document, document)
        |> assign(:log_count, 0)
        |> assign(:tab, "Response")
        |> assign(:request_id, nil)
        |> assign(:show_raw_res_body, false)
        |> assign(:show_raw_req_body, false)
        |> assign(:open_requests, %{})
        |> assign(:main_left_tab, :req_res)
        |> stream(:logs, [])

      other ->
        socket # no file selected
    end
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

  def handle_event("toggle-requests", %{"block-id" => block_id}, socket = %{assigns: %{open_requests: open_requests}}) do
    # persist document here
    open_requests = case open_requests[block_id] do
      nil -> Map.put(open_requests, block_id, block_id)
      _ -> Map.delete(open_requests, block_id)
    end

    {:noreply, assign(socket, :open_requests, open_requests)}
  end

  def handle_event("update", %{"_target" => ["title"], "title" => title}, socket = %{assigns: %{doc_pid: doc_pid}}) do
    Document.update_title(doc_pid, title)
    {:noreply, socket}
  end

  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    # switching subtab to headers, better to keep separate state
    {:noreply, assign(socket, tab: tab)}
  end

  def handle_event("switch_res_body_format", _, socket) do
    {:noreply, assign(socket, show_raw_res_body: !socket.assigns.show_raw_res_body)}
  end
  def handle_event("switch_req_body_format", _, socket) do
    {:noreply, assign(socket, show_raw_req_body: !socket.assigns.show_raw_req_body)}
  end

  def handle_event("select-request", %{"block-id" => block_id, "request-index" => request_index}, socket) do
    {request_index, _} = Integer.parse(request_index)
    {:noreply, assign(socket, request_id: {block_id, request_index})}
  end

  def handle_event("change-main-left-tab", %{"tab-id" => tab_id}, socket) do
    {:noreply, assign(socket, :main_left_tab, String.to_existing_atom(tab_id))}
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


  defp tab_colors(selected_tab, selected_tab), do:  "text-white"
  defp tab_colors(_, _), do:  "text-gray-500 hover:text-gray-300"

  defp tab_visibility(selected_tab, selected_tab), do: "block"
  defp tab_visibility(_, _), do: "hidden"

end
