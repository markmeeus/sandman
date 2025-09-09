defmodule SandmanWeb.Phoenix.LiveView.App do
  # In Phoenix v1.6+ apps, the line is typically: use MyAppWeb, :live_view
  use Phoenix.LiveView,
    container: {:div, class: "h-full"}

  alias Sandman.Document
  alias Sandman.FileAccess
  alias SandmanWeb.UpdateBar
  alias Phoenix.PubSub

  def mount(params, session, socket) do
    socket = case params["file"] do
      "" -> socket
      nil -> socket
      file_name ->
        if(File.exists?(file_name)) do
          open_file(file_name, socket)
        else
          socket
        end
    end
    # not sure what this was used for
    # window_id = case params["window_id"] do
    #   nil -> :browser
    #   id ->
    #     String.to_existing_atom(params["window_id"])
    # end
    socket = assign(socket, :window_id, :browser)
    {:ok, socket}
  end

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
      <div id="app-wrapper" class="flex flex-row" phx-hook="HomeHook" data-window_id={@window_id}>

          <div id="document-container" style="overflow:clip;" class="h-screen">
            <div id="document-root" class="h-screen">
              <SandmanWeb.LiveView.Document.render doc_pid={@doc_pid} open_requests={@open_requests} requests={@document.requests} document={@document.document} selected_request={@selected_request} code="" />
            </div>
          </div>

        <div class="gutter gutter-horizontal" id="doc-req-gutter" phx-update="ignore"></div>

        <div id="req-res-container" class="h-screen flex-grow bg-neutral-800" style="overflow:scroll;" phx-hook="MaintainWidth">
          <div class="bg-neutral-700 border-b border-neutral-600">
            <div class="px-3">
              <nav class="flex space-x-4" aria-label="Tabs">
                <a href="#" class={"#{tab_colors(@main_left_tab, :req_res)} px-3 py-2 text-xs font-medium"} phx-click="change-main-left-tab" phx-value-tab-id="req_res">Inspector</a>
                <a href="#" class={"#{tab_colors(@main_left_tab, :logs)} px-3 py-2 text-xs font-medium"}  phx-click="change-main-left-tab" phx-value-tab-id="logs">Logs</a>
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

  defp start_document(mode, socket) do
    case FileAccess.select_file(mode) do
      file_name when is_bitstring(file_name) ->
        url = SandmanWeb.Endpoint.url()
          |> URI.parse()
          |> URI.append_query(URI.encode_query(%{file: file_name}))
          |> URI.to_string()

        :wx_misc.launchDefaultBrowser(url);
        #open_file(file_name, socket)

      _other ->
        socket # no file selected
    end
  end

  def handle_event("ctrl-key", _, socket), do: {:noreply, socket}

  def handle_event("open_file", _, socket) do
    {:noreply, start_document(:open, socket)}
  end

  def handle_event("new_file", _, socket) do
    {:noreply, start_document(:new, socket)}
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

  def handle_event("run-all-blocks", _, socket = %{assigns: %{doc_pid: doc_pid}}) do
    Document.run_all_blocks(doc_pid)
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

  def handle_event("select-request", %{"block-id" => block_id, "line_nr" => line_nr, "request-index" => request_index}, socket) do
    socket = case Integer.parse(line_nr) do
      {line_nr, _} ->
        push_event(socket, "monaco-update-selected", %{block_id: block_id, selected: %{line_nr: line_nr}})
      nil -> socket
    end
    {request_index, _} = Integer.parse(request_index)

    # Auto-switch to Request Info tab when selecting a request
    socket = assign(socket, :main_left_tab, :req_res)

    socket = socket
    |> assign(:request_id, {block_id, request_index})
    |> assign(:selected_request, {block_id, request_index})

    {:noreply, socket}
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

  def handle_info({:request_recorded, block_id}, socket = %{assigns: %{doc_pid: doc_pid}}) do
    doc = Document.get(doc_pid)
    stats = get_block_request_stats(doc, block_id)
    socket = push_event(socket, "monaco-update-#{block_id}", %{stats: stats})
    {:noreply, assign(socket, :document, doc)}
  end

  def handle_info({:log, log}, socket = %{assigns: %{doc_pid: _doc_pid, log_count: log_count}}) do
    socket = socket
    |> assign(:log_count, log_count + 1)
    |> stream_insert(:logs, Map.put(log, :id, log_count))
    {:noreply, socket}
  end


  defp tab_colors(selected_tab, selected_tab), do:  "text-neutral-100 bg-neutral-600 border-b-2 border-neutral-100"
  defp tab_colors(_, _), do:  "text-neutral-400 hover:text-neutral-200 hover:bg-neutral-600/50 border-b-2 border-transparent hover:border-neutral-400"

  defp tab_visibility(selected_tab, selected_tab), do: "block"
  defp tab_visibility(_, _), do: "hidden"

  def open_file(file_name, socket) do
    # start_doc
    doc_id = UUID.uuid4()
    PubSub.subscribe(Sandman.PubSub, "document:#{doc_id}")

    {:ok, doc_pid} = Document.start_link(doc_id, file_name)
    document= Document.get(doc_pid)
    socket
    |> assign(:doc_pid, doc_pid)
    |> assign(:document, document)
    |> assign(:log_count, 0)
    |> assign(:tab, "Response")
    |> assign(:request_id, nil)
    |> assign(:selected_request, nil)
    |> assign(:show_raw_res_body, false)
    |> assign(:show_raw_req_body, false)
    |> assign(:open_requests, %{})
    |> assign(:main_left_tab, :req_res)
    |> stream(:logs, [])
  end

  defp get_block_request_stats(%{requests: requests}, block_id) do
    requests = (requests[block_id] || [])
    Enum.reduce(requests, %{ok: [], warn: [], error: []}, fn(req, acc) ->
      request_level = get_request_level(req)
      Map.put(acc, request_level, acc[request_level] ++ [req.call_info])
    end)
  end

  defp get_request_level(%{res: %{status: status}}) when status < 400, do: :ok
  defp get_request_level(%{res: %{status: status}}) when status < 500, do: :warn
  defp get_request_level(_), do: :error
end
