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
    socket = socket
    |> assign(:window_id, :browser)
    |> assign(:focused_block, nil)
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

          <div id="document-container" style="overflow:clip;" class="h-screen" phx-hook="MaintainSplitDimensions">
            <div id="document-root" class="h-screen">
              <SandmanWeb.LiveView.Document.render doc_pid={@doc_pid} open_requests={@open_requests} requests={@document.requests} document={@document.document} selected_request={@selected_request} selected_block={@selected_block} focused_block={@focused_block} confirming_removal={@confirming_removal} code="" />
            </div>
          </div>

        <div class="gutter gutter-horizontal" id="doc-req-gutter" phx-update="ignore"></div>

        <div id="req-res-container" class="h-screen flex-grow bg-neutral-800 flex flex-col" phx-hook="MaintainSplitDimensions">
          <div class="bg-neutral-700 border-b border-neutral-600 flex-shrink-0">
            <div class="px-3">
              <nav class="flex space-x-4" aria-label="Tabs">
                <a href="#" class={"#{tab_colors(@main_left_tab, :req_res)} px-3 py-2 text-xs font-medium"} phx-click="show-main-left-tab" phx-value-tab-id="req_res">Inspector</a>
                <a href="#" class={"#{tab_colors(@main_left_tab, :logs)} px-3 py-2 text-xs font-medium"}  phx-click="show-main-left-tab" phx-value-tab-id="logs">Logs</a>
                <a href="#" class={"#{tab_colors(@main_left_tab, :docs)} px-3 py-2 text-xs font-medium"}  phx-click="show-main-left-tab" phx-value-tab-id="docs">Docs</a>
              </nav>
            </div>
          </div>
            <div class={"pt-2 flex-1 overflow-auto min-h-0 #{tab_visibility(@main_left_tab, :req_res)}"}>
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
            <div class={"pt-1 px-1 flex-1 flex flex-col min-h-0 #{tab_visibility(@main_left_tab, :logs)}"} >
              <SandmanWeb.LiveView.Log.render logs={@streams.logs} />
            </div>
            <div class={"flex-1 overflow-auto min-h-0 #{tab_visibility(@main_left_tab, :docs)}"} >
              <SandmanWeb.LiveView.Docs.render docs_expanded_namespaces={@docs_expanded_namespaces} docs_expanded_functions={@docs_expanded_functions} />
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

  def handle_event("add-code", %{"block-id" => block_id}, socket = %{assigns: %{doc_pid: doc_pid}}) do
    Document.add_block(doc_pid, block_id, "lua")
    {:noreply, socket}
  end

  def handle_event("add-markdown", %{"block-id" => block_id}, socket = %{assigns: %{doc_pid: doc_pid}}) do
    Document.add_block(doc_pid, block_id, "markdown")
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

  def handle_event("shortcut", %{"type" => "run-block", "block-id" => block_id}, socket = %{assigns: %{doc_pid: doc_pid, document: %{document: doc_data}}}) do
    # Check if block can be executed (same logic as render_run_button)
    block = Enum.find(doc_data.blocks, & &1.id == block_id)
    preceding_block = get_preceding_block(doc_data.blocks, block_id)

    if can_run_block?(block, preceding_block) do
      Document.run_block(doc_pid, block_id, %{})
    end

    {:noreply, socket}
  end

  def handle_event("shortcut", %{"type" => "run-block-and-next", "block-id" => block_id}, socket = %{assigns: %{doc_pid: doc_pid, document: %{document: doc_data}}}) do
    # Check if block can be executed
    block = Enum.find(doc_data.blocks, & &1.id == block_id)
    preceding_block = get_preceding_block(doc_data.blocks, block_id)

    if can_run_block?(block, preceding_block) do
      Document.run_block(doc_pid, block_id, %{move_next: true})
    end

    {:noreply, socket}
  end

  def handle_event("shortcut", %{"type" => "run-all-blocks", "block-id" => _block_id}, socket = %{assigns: %{doc_pid: doc_pid}}) do
    Document.run_all_blocks(doc_pid)
    {:noreply, socket}
  end

  def handle_event("show-remove-confirmation", %{"block-id" => block_id}, socket) do
    {:noreply, assign(socket, :confirming_removal, block_id)}
  end

  def handle_event("cancel-remove-block", _, socket) do
    {:noreply, assign(socket, :confirming_removal, nil)}
  end

  def handle_event("confirm-remove-block", %{"block-id" => block_id}, socket = %{assigns: %{doc_pid: doc_pid}}) do
    # persist document here
    Document.remove_block(doc_pid, block_id)
    {:noreply, assign(socket, :confirming_removal, nil)}
  end

  def handle_event("remove-block", %{"block-id" => block_id}, socket = %{assigns: %{doc_pid: doc_pid}}) do
    # persist document here
    Document.remove_block(doc_pid, block_id)
    {:noreply, socket}
  end

  def handle_event("block-focused", %{"block_id" => block_id}, socket) do
    # Only set focused_block for markdown blocks, lua blocks don't need this state
    current_document = socket.assigns[:document]
    if current_document do
      block = Enum.find(current_document.document.blocks, & &1.id == block_id)
      if block && block.type == "markdown" do
        {:noreply, assign(socket, :focused_block, block_id)}
      else
        {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
  end

  def handle_event("block-blurred", %{"block_id" => block_id}, socket) do
    # Clear focused_block for markdown blocks when they truly lose focus
    current_document = socket.assigns[:document]
    # Force re-render by updating socket assigns
    socket = assign(socket, :force_render, System.system_time(:nanosecond))
    if current_document do
      block = Enum.find(current_document.document.blocks, & &1.id == block_id)
      if block && block.type == "markdown" && socket.assigns[:focused_block] == block_id do
        IO.inspect({"resetting focused_block", block_id})
        {:noreply, assign(socket, :focused_block, nil)}
      else
        IO.inspect({"hier?", block.type, socket.assigns[:focused_block], block_id, block.id})
        {:noreply, assign(socket, :focused_block, nil)}
        #{:noreply, socket}
      end
    else
      {:noreply, assign(socket, :focused_block, nil)}
      #{:noreply, socket}
    end
  end

  def handle_event("focus-block", %{"block-id" => block_id}, socket) do
    # For markdown blocks, set focused_block and also set selected_block
    current_document = socket.assigns[:document]
    if current_document do
      block = Enum.find(current_document.document.blocks, & &1.id == block_id)
      if block && block.type == "markdown" do
        socket = socket
        |> assign(:focused_block, block_id)
        |> assign(:selected_block, block_id)
        |> push_event("scroll-to-selected", %{block_id: block_id})
        {:noreply, socket}
      else
        # For non-markdown blocks, clear focused_block and set selected_block
        socket = socket
        |> assign(:focused_block, nil)
        |> assign(:selected_block, block_id)
        |> push_event("scroll-to-selected", %{block_id: block_id})
        {:noreply, socket}
      end
    else
      socket = socket
      |> assign(:focused_block, block_id)
      |> push_event("scroll-to-selected", %{block_id: block_id})
      {:noreply, socket}
    end
  end

  def handle_event("unfocus-markdown", _, socket) do
    {:noreply, assign(socket, :focused_block, nil)}
  end

  def handle_event("keydown", %{"key" => "Escape"}, socket) do
    {:noreply, assign(socket, :focused_block, nil)}
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

  def handle_event("show-main-left-tab", %{"tab-id" => tab_id}, socket) do
    tab_atom = String.to_existing_atom(tab_id)
    socket = assign(socket, :main_left_tab, tab_atom)

    # When switching to logs tab, scroll to bottom to show latest messages
    socket = if tab_atom == :logs do
      push_event(socket, "scroll-to-log", %{})
    else
      socket
    end

    {:noreply, socket}
  end

  def handle_event("toggle-docs-namespace", %{"namespace" => namespace}, socket) do
    current_expanded = socket.assigns.docs_expanded_namespaces

    new_expanded = if MapSet.member?(current_expanded, namespace) do
      MapSet.delete(current_expanded, namespace)
    else
      MapSet.put(current_expanded, namespace)
    end

    {:noreply, assign(socket, :docs_expanded_namespaces, new_expanded)}
  end

  def handle_event("toggle-docs-function", %{"function" => function_name}, socket) do
    current_expanded = socket.assigns.docs_expanded_functions

    new_expanded = if MapSet.member?(current_expanded, function_name) do
      MapSet.delete(current_expanded, function_name)
    else
      MapSet.put(current_expanded, function_name)
    end

    {:noreply, assign(socket, :docs_expanded_functions, new_expanded)}
  end

  def handle_event("cursor-moved", %{"block-id" => block_id}, socket) do
    # Preserve focused_block when setting selected_block
    current_focused = socket.assigns[:focused_block]
    socket = socket
    |> assign(:selected_block, block_id)
    |> assign(:focused_block, current_focused)
    |> push_event("scroll-to-selected", %{block_id: block_id})

    {:noreply, socket}
  end

  def handle_event("navigate-up", _, socket = %{assigns: %{document: document}}) do
    selected_block = Map.get(socket.assigns, :selected_block, nil)
    blocks = document.document.blocks
    case find_previous_block(blocks, selected_block) do
      nil -> {:noreply, socket}  # Already at first block or no blocks
      previous_block_id ->
        socket = socket
        |> assign(:selected_block, previous_block_id)
        |> push_event("scroll-to-selected", %{block_id: previous_block_id})
        {:noreply, socket}
    end
  end

  def handle_event("navigate-down", _, socket = %{assigns: %{document: document}}) do
    selected_block = Map.get(socket.assigns, :selected_block, nil)
    blocks = document.document.blocks
    case find_next_block(blocks, selected_block) do
      nil -> {:noreply, socket}  # Already at last block or no blocks
      next_block_id ->
        socket = socket
        |> assign(:selected_block, next_block_id)
        |> push_event("scroll-to-selected", %{block_id: next_block_id})
        {:noreply, socket}
    end
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
    |> push_event("scroll-to-log", %{})
    {:noreply, socket}
  end

  def handle_info({:block_state_changed, block_id, new_state}, socket = %{assigns: %{doc_pid: doc_pid}}) do
    # Refresh document to get updated block states - LiveView will automatically re-render
    document = Document.get(doc_pid)
    socket = assign(socket, :document, document)

    {:noreply, socket}
  end

  def handle_info({:block_executed, block_id, context}, socket = %{assigns: %{document: %{document: doc_data}}}) do
    # Handle block execution completion with context
    if Map.get(context, :move_next, false) do
      # Find the next block and send focus command
      next_block_id = get_next_block_id(doc_data.blocks, block_id)

      if next_block_id do
        {:noreply, push_event(socket, "focus-block", %{"block-id" => next_block_id})}
      else
        {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
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
    |> assign(:selected_block, nil)
    |> assign(:focused_block, nil)
    |> assign(:show_raw_res_body, false)
    |> assign(:show_raw_req_body, false)
    |> assign(:open_requests, %{})
    |> assign(:main_left_tab, :req_res)
    |> assign(:docs_expanded_namespaces, MapSet.new())
    |> assign(:docs_expanded_functions, MapSet.new())
    |> assign(:confirming_removal, nil)
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

  # Helper functions for block execution validation
  defp get_preceding_block(blocks, block_id) do
    block_index = Enum.find_index(blocks, & &1.id == block_id)
    if block_index && block_index > 0 do
      # Find the preceding lua block, not just the immediately previous block
      blocks
      |> Enum.take(block_index)
      |> Enum.reverse()
      |> Enum.find(& &1.type == "lua")
    else
      nil
    end
  end

  defp get_next_block_id(blocks, block_id) do
    block_index = Enum.find_index(blocks, & &1.id == block_id)
    if block_index && block_index < length(blocks) - 1 do
      next_block = Enum.at(blocks, block_index + 1)
      next_block.id
    else
      nil
    end
  end

  # Helper functions for block navigation
  defp find_previous_block(blocks, selected_block_id) do
    case selected_block_id do
      nil ->
        # If no block is selected, select the first block
        case blocks do
          [first_block | _] -> first_block.id
          [] -> nil
        end
      current_id ->
        # Find the block before the current one
        block_index = Enum.find_index(blocks, & &1.id == current_id)
        if block_index && block_index > 0 do
          previous_block = Enum.at(blocks, block_index - 1)
          previous_block.id
        else
          nil  # Already at first block
        end
    end
  end

  defp find_next_block(blocks, selected_block_id) do
    case selected_block_id do
      nil ->
        # If no block is selected, select the first block
        case blocks do
          [first_block | _] -> first_block.id
          [] -> nil
        end
      current_id ->
        # Find the block after the current one
        block_index = Enum.find_index(blocks, & &1.id == current_id)
        if block_index && block_index < length(blocks) - 1 do
          next_block = Enum.at(blocks, block_index + 1)
          next_block.id
        else
          nil  # Already at last block
        end
    end
  end

  defp can_run_block?(block = %{type: "lua"}, preceding_block) do
    block_state = Map.get(block, :state, :empty)
    preceding_state = if preceding_block, do: Map.get(preceding_block, :state, :empty), else: nil

    case {block_state, preceding_state} do
      # If preceding block is :empty, can't run
      {_, :empty} when not is_nil(preceding_block) -> false

      # If block is :executed or :errored, can rerun
      {state, _} when state in [:executed, :errored] -> true

      # If preceding block is :executed or no preceding block, can run
      {_, preceding} when preceding in [:executed, nil] -> true

      # All other cases (preceding block is :running, :errored) - can't run
      _ -> false
    end
  end
  defp can_run_block?(_, _), do: false # only lua can run
end
