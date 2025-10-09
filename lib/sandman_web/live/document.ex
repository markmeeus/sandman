defmodule SandmanWeb.LiveView.Document do
  # In Phoenix v1.6+ apps, the line is typically: use MyAppWeb, :live_view
  use Phoenix.Component
  import Sandman.RequestFormatting
  alias Sandman.MarkdownRenderer

  def mount(_params, _session, socket) do
    socket = assign(socket, :code, "some code")
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div phx-hook="DocumentHook" id="document" class="h-screen bg-neutral-900" style="overflow:scroll; overscroll-behavior: none">

      <div style="overflow:scroll;">

        <%= case @document.blocks do
          [] -> render_empty_state(assigns)
          _ -> render_blocks(assigns)
        end %>
      </div>
    </div>
    """
  end

  def render_empty_state(assigns) do
    ~H"""
      <div class="group h-5">
        <div class="flex flex-row">
          <div class="flex-grow"/>
          <button class="pt-1 mr-3 text-sm text-neutral-300 hover:text-neutral-100" phx-click="add-code" phx-value-block-id="-"><span class="font-bold">+</span> Add Code</button>
          <button class="pt-1 mr-3 text-sm text-neutral-300 hover:text-neutral-100" phx-click="add-markdown" phx-value-block-id="-"><span class="font-bold">+</span> Add Markdown</button>
          <div class="flex-grow"/>
        </div>
      </div>
    """
  end
  def render_blocks(assigns) do
    ~H"""
    <div class="flex flex-row">
      <!-- Run All button positioned above status indicators -->
      <div class="w-8 flex flex-col items-center mt-2">
        <div class="flex justify-center w-full">
          <button class="fixed mb-2 px-2 py-1 bg-green-600 text-white text-xs rounded hover:bg-green-700 transition-colors z-50" phx-click="run-all-blocks">
            ▶
          </button>
        </div>
        <!-- Connecting line from Run All button to first block -->
        <%= if length(@document.blocks) > 0 do %>
          <div class="w-0.5 flex-grow bg-neutral-400"></div>
        <% end %>
      </div>
      <!-- Top insert block button -->
      <div class="flex-grow py-2">
        <div class="group h-5">
          <div class="flex flex-row">
            <div class="flex-grow"/>
            <button class="pt-1 mr-3 text-sm text-neutral-300 hover:text-neutral-100 hidden group-hover:block" phx-click="add-code" phx-value-block-id="-"><span class="font-bold">+</span> Add Code</button>
            <button class="pt-1 mr-3 text-sm text-neutral-300 hover:text-neutral-100 hidden group-hover:block" phx-click="add-markdown" phx-value-block-id="-"><span class="font-bold">+</span> Add Markdown</button>
            <div class="flex-grow"/>
          </div>
        </div>
      </div>
    </div>
    <%= for {block, index} <- Enum.with_index(@document.blocks) do%>
      <% preceding_block = get_preceding_lua_block(@document.blocks, index) %>
      <div class="flex flex-row my-1 no-select">
        <!-- Status indicator column -->
        <div class="w-8 flex flex-col items-center justify-end">
        <!-- Connecting line from above (Run All button or previous block) -->
        <%= render_connecting_line(%{state: Map.get(block, :state, :empty)}) %>
            <!-- Status dot -->
            <%= if block.type == "lua" do %>
            <%= render_block_state_indicator(%{state: Map.get(block, :state, :empty)}) %>
            <% end %>
        </div>
        <!-- Block content -->
        <div class="flex-grow min-w-0 pr-2">
          <div class={"group rounded #{if block.type == "lua", do: "border", else: ""} #{if @selected_block && @selected_block == block.id, do: "selected-block", else: "border-neutral-700"}"}>
            <%= render_block_content(%{block: block, focused_block: @focused_block}) %>
            <div class="px-1" >
              <%= if(@open_requests[block.id]) do %>
                <%= for {req, req_index} <- Enum.with_index(requests_for_block(@requests, block.id)) do%>
                  <%= render_request(%{req: req, block_id: block.id, request_index: req_index, selected_request: @selected_request}) %>
                <% end %>
              <%end%>
            </div>
            <%= if block.type == "lua" do %>
                <div class="min-h-5">
                  <div class="flex flex-row fs-2 my-2 px-6 text-sm sticky">
                    <%= render_run_button(%{block: block, preceding_block: preceding_block}) %>
                    <div class="flex-grow"/>
                    <%= render_block_stats(%{requests: requests_for_block(@requests, block.id), block: block, is_open: !!@open_requests[block.id]}) %>
                    <div class="flex-grow"/>
                    <%= if @confirming_removal == block.id do %>
                      <!-- Confirmation buttons -->
                      <button class="text-sm text-red-400 hover:text-red-300 transition-colors p-1 rounded hover:bg-red-900/20 mr-1" phx-click="confirm-remove-block" phx-value-block-id={block.id}>
                        Delete Block
                      </button>
                      <button class="text-sm text-neutral-400 hover:text-neutral-300 transition-colors p-1 rounded hover:bg-neutral-800/20" phx-click="cancel-remove-block">
                        Cancel
                      </button>
                    <% else %>
                      <!-- Trash icon button -->
                      <button class="text-sm text-neutral-400 hover:text-red-400 invisible group-hover:visible transition-colors p-1 rounded hover:bg-red-900/20" phx-click="show-remove-confirmation" phx-value-block-id={block.id}>
                        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 640" class="w-4 h-4 fill-current"><!--!Font Awesome Free v7.0.1 by @fontawesome - https://fontawesome.com License - https://fontawesome.com/license/free Copyright 2025 Fonticons, Inc.--><path d="M232.7 69.9C237.1 56.8 249.3 48 263.1 48L377 48C390.8 48 403 56.8 407.4 69.9L416 96L512 96C529.7 96 544 110.3 544 128C544 145.7 529.7 160 512 160L128 160C110.3 160 96 145.7 96 128C96 110.3 110.3 96 128 96L224 96L232.7 69.9zM128 208L512 208L512 512C512 547.3 483.3 576 448 576L192 576C156.7 576 128 547.3 128 512L128 208zM216 272C202.7 272 192 282.7 192 296L192 488C192 501.3 202.7 512 216 512C229.3 512 240 501.3 240 488L240 296C240 282.7 229.3 272 216 272zM320 272C306.7 272 296 282.7 296 296L296 488C296 501.3 306.7 512 320 512C333.3 512 344 501.3 344 488L344 296C344 282.7 333.3 272 320 272zM424 272C410.7 272 400 282.7 400 296L400 488C400 501.3 410.7 512 424 512C437.3 512 448 501.3 448 488L448 296C448 282.7 437.3 272 424 272z"/></svg>
                      </button>
                    <% end %>
                  </div>
                </div>
            <%end%>
          </div>
        </div>
      </div>

      <!-- Insert block row between blocks -->
      <div class="flex flex-row">
        <div class="w-8"></div> <!-- Empty space to align with status indicators -->
        <div class="flex-grow">
          <div class="group h-5">
            <div class="flex flex-row">
              <div class="flex-grow"/>
              <button class="mr-3 text-sm text-neutral-300 hover:text-neutral-100 invisible group-hover:visible" phx-click="add-code" phx-value-block-id={block.id}><span class="font-bold">+</span> Add Code</button>
              <button class="mr-3 text-sm text-neutral-300 hover:text-neutral-100 invisible group-hover:visible" phx-click="add-markdown" phx-value-block-id={block.id}><span class="font-bold">+</span> Add Markdown</button>
              <div class="flex-grow"/>
            </div>
          </div>
        </div>
      </div>
    <% end %>
    """
  end

  defp render_request(assigns = %{req: %{ res: nil, lua_result: [nil, err] }}) when is_bitstring(err) do
    # TODO: deze moeten we nog fixen, die assigns zijn hier totaal gefaked!
    is_selected = assigns.selected_request == {assigns.block_id, assigns.request_index}
    row_class = if is_selected, do: "request-row request-row-selected flex flex-row-reverse text-xs text-red-400 rounded-b pb-1 px-1", else: "request-row flex flex-row-reverse text-xs text-red-400 rounded-b pb-1 px-1"

    ~H"""
      <div class="flex flex-col">
        <div class={row_class} data-block-id={assigns.block_id} data-request-index={assigns.request_index}>
          <%= format_request(@req)%>: <%= err %>
        </div>
      </div>
    """
  end

  defp render_request(assigns) do
    is_selected = assigns.selected_request == {assigns.block_id, assigns.request_index}

    row_class = if is_selected do
      "request-row request-row-selected flex flex-row text-xs text-neutral-100 rounded-b pb-1 px-1 pt-1 bg-neutral-700 hover:bg-neutral-600 transition-colors duration-150"
    else
      "request-row flex flex-row text-xs text-neutral-300 rounded-b pb-1 px-1 pt-1 hover:bg-neutral-800 transition-colors duration-150"
    end

    ~H"""
      <div class="flex flex-col">
        <a class={row_class}
            data-block-id={assigns.block_id} data-request-index={assigns.request_index}
            href="#" phx-click="select-request" phx-value-block-id={assigns.block_id} phx-value-line_nr={@req.call_info.line_nr} phx-value-request-index={assigns.request_index}>
          <div class="flex-grow">
            <span><%= format_request(@req) %></span>
          </div>
          <div>
            <.format_response res={@req.res} />
          </div>
        </a>
      </div>
    """
  end

  defp render_block_stats(assigns = %{is_open: true}) do
    ~H"""
    <a href="#" class="px-1 text-neutral-300 hover:text-neutral-100 transition-colors" phx-click="toggle-requests" phx-value-block-id={@block.id}>▲</a>
    """
  end

  defp render_block_stats(assigns) do
    ~H"""
    <%= case Enum.count(@requests) do %>
    <% 0 -> %>
    <% count -> %>
      <a href="#" class="px-1 text-neutral-300 hover:text-neutral-100 transition-colors" phx-click="toggle-requests" phx-value-block-id={@block.id}><%=count%> requests ▼</a>
    <% end %>
    """
  end

  defp requests_for_block(requests, block_id) do
    requests[block_id] || []
  end

  defp get_preceding_lua_block(blocks, current_index) do
    if current_index == 0 do
      nil
    else
      blocks
      |> Enum.take(current_index)
      |> Enum.reverse()
      |> Enum.find(& &1.type == "lua")
    end
  end

  defp render_block_content(assigns) do
    is_focused = assigns.focused_block == assigns.block.id
    is_markdown = assigns.block.type == "markdown"

    ~H"""
    <div class="rounded-t p-1">
      <!-- Always render Monaco editor, but hide it for unfocused markdown blocks -->
      <div class={if is_markdown && !is_focused, do: "hidden", else: ""}
           phx-update="ignore" id={"monaco-wrapper-#{@block.id}"}>
        <div id={"monaco-#{@block.id}"} phx-hook="MonacoHook" data-block-id={@block.id} data-block-type={@block.type}><%= @block.code %></div>
      </div>

      <!-- Render text content for unfocused markdown blocks -->
      <%= if is_markdown && !is_focused do %>
        <div class="prose prose-sm text-[12px] prose-invert max-w-none text-neutral-200 font-mono leading-relaxed p-2 cursor-text hover:bg-neutral-800 transition-colors"
             phx-click="focus-block" phx-value-block-id={@block.id} >
             <style>
              h1 { color:#AAA !important; margin-top: 0 !important;}
              h2 { color:#AAA !important; margin-top: 0 !important;}
              h3 { color:#AAA !important; margin-top: 0 !important;}
              h4 { color:#AAA !important; margin-top: 0 !important;}
              h5 { color:#AAA !important; margin-top: 0 !important;}
              h6 { color:#AAA !important; margin-top: 0 !important;}
              p { color:#AAA !important;}
              ul { color:#AAA !important;}
              ol { color:#AAA !important;}
              li { color:#AAA !important;}
              a { color:#AAA !important;}
              img { color:#AAA !important;}
              blockquote { color:#AAA !important;}
              code { color:#AAA !important;}
              pre { color:#AAA !important;}
              table { color:#AAA !important;}
              thead { color:#AAA !important;}
              tbody { color:#AAA !important;}
              tfoot { color:#AAA !important;}
              tr { color:#AAA !important;}
              td { color:#AAA !important;}
              th { color:#AAA !important;}
              hr { color:#AAA !important;}

             </style>
             <div class="markdown-wrappper">
              <%= MarkdownRenderer.render_with_target_blank(@block.code) %></div>
             </div>
      <% end %>
    </div>
    """
  end

  defp render_run_button(assigns) do
    block_state = Map.get(assigns.block, :state, :empty)
    preceding_state = if assigns.preceding_block, do: Map.get(assigns.preceding_block, :state, :empty), else: nil

    case {block_state, preceding_state} do
      # If preceding block is :empty, don't show button
      {_, :empty} when not is_nil(assigns.preceding_block) ->
        ~H"""
        <div class="p-1"></div>
        """

      # If block is :executed or :errored, show rerun icon
      {state, _} when state in [:executed, :errored] ->
        ~H"""
        <button class="text-green-600 hover:text-green-700 transition-colors p-1 rounded hover:bg-green-900/20" phx-click="run-block" phx-value-block-id={@block.id} title="Re-run block">
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" class="w-4 h-4 fill-current">
            <path d="M8 3a5 5 0 1 0 4.546 2.914.5.5 0 0 1 .908-.417A6 6 0 1 1 8 2v1z"/>
            <path d="M8 4.466V.534a.25.25 0 0 1 .41-.192l2.36 1.966c.12.1.12.284 0 .384L8.41 4.658A.25.25 0 0 1 8 4.466z"/>
          </svg>
        </button>
        """

      # If preceding block is :executed or no preceding block, show run icon
      {_, preceding} when preceding in [:executed, nil] ->
        ~H"""
        <button class="text-green-600 hover:text-green-700 transition-colors p-1 rounded hover:bg-green-900/20" phx-click="run-block" phx-value-block-id={@block.id} title="Run block">
          <span>▶</span>
        </button>
        """

      # All other cases (preceding block is :running, :errored) - don't show button
      _ ->
        ~H"""
        <div class="p-1"></div>
        """
    end
  end

  defp render_connecting_line(assigns) do
    case assigns.state do
      :executed ->
        ~H"""
        <div class="w-0.5 flex-grow bg-green-500 mb-1"></div>
        """
      :errored ->
        ~H"""
        <div class="w-0.5 flex-grow bg-red-500 mb-1"></div>
        """
      :running ->
        ~H"""
        <div class="w-0.5 flex-grow bg-neutral-400 mb-1"></div>
        """
      _ -> # :empty or any other state
        ~H"""
        <div class="w-0.5 flex-grow bg-neutral-400 mb-1"></div>
        """
    end
  end

  defp render_block_state_indicator(assigns) do
    case assigns.state do
      :executed ->
        ~H"""
        <div class="w-3 h-3 mb-1 bg-green-500 rounded-full flex-shrink-0" title="Executed successfully"></div>
        """
      :errored ->
        ~H"""
        <div class="w-3 h-3 mb-1 bg-red-500 rounded-full flex-shrink-0" title="Execution failed"></div>
        """
      :running ->
        ~H"""
        <div class="w-3 h-3 mb-1 flex-shrink-0 flex items-center justify-center" title="Running...">
          <div class="w-3 h-3 border-2 border-neutral-400 border-t-transparent rounded-full animate-spin"></div>
        </div>
        """
      _ -> # :empty or any other state
        ~H"""
        <div class="w-3 h-3 mb-1 bg-neutral-400 rounded-full flex-shrink-0" title="Ready to run"></div>
        """
    end
  end

  defp format_response(nil), do: nil
  defp format_response(assigns) do
     ~H"""
     <span class="text-neutral-400 bg-neutral-700 px-1.5 py-0.5 rounded text-xs font-medium mx-1">
        <%= @res.status %>
      </span>
     """
  end
end
