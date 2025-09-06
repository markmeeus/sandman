defmodule SandmanWeb.LiveView.Document do
  # In Phoenix v1.6+ apps, the line is typically: use MyAppWeb, :live_view
  use Phoenix.Component
  import Sandman.RequestFormatting
  def mount(_params, _session, socket) do
    socket = assign(socket, :code, "some code")
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div phx-hook="DocumentHook" id="document" class="h-screen" style="overflow:scroll; overscroll-behavior: none">

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
          <button class="pt-1 mr-3 text-lg" phx-click="add-block" phx-value-block-id="-"><span class="font-bold">+</span> Insert block</button>
          <div class="flex-grow"/>
        </div>
      </div>
    """
  end
  def render_blocks(assigns) do
    ~H"""
    <div class="group h-5">
      <div class="flex flex-row">
        <div class="flex-grow"/>
        <button class="pt-1 mr-3 text-sm hidden group-hover:block" phx-click="add-block" phx-value-block-id="-"><span class="font-bold">+</span> Insert block</button>
        <div class="flex-grow"/>
      </div>
    </div>
    <%= for block <- @document.blocks do%>
      <div class="my-1 px-2 no-select">
        <div class="group rounded" style="border: 1px solid rgb(30, 30, 30);">
          <div class="rounded-t p-2" style="background-color: rgb(30, 30, 30);" phx-update="ignore" id={"monaco-wrapper-#{block.id}"}>
            <div id={"monaco-#{block.id}"} phx-hook="MonacoHook" data-block-id={block.id} ><%= block.code %></div>
          </div>
          <div class="px-1" >
            <%= if(@open_requests[block.id]) do %>
              <%= for {req, index} <- Enum.with_index(requests_for_block(@requests, block.id)) do%>
                <%= render_request(%{req: req, block_id: block.id, request_index: index}) %>
              <% end %>
            <%end%>
          </div>
          <div class="min-h-5">
            <div class="flex flex-row fs-2 my-2 px-6 text-sm sticky">
              <button phx-click="run-block" phx-value-block-id={block.id}><span><%="▶"%></span></button>
              <div class="flex-grow"/>
              <%= render_block_stats(%{requests: requests_for_block(@requests, block.id), block: block, is_open: !!@open_requests[block.id]}) %>
              <div class="flex-grow"/>
              <button class=" text-sm invisible group-hover:visible" phx-click="remove-block" phx-value-block-id={block.id}>
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 640" class="w-4 h-4 fill-current"><!--!Font Awesome Free v7.0.1 by @fontawesome - https://fontawesome.com License - https://fontawesome.com/license/free Copyright 2025 Fonticons, Inc.--><path d="M232.7 69.9C237.1 56.8 249.3 48 263.1 48L377 48C390.8 48 403 56.8 407.4 69.9L416 96L512 96C529.7 96 544 110.3 544 128C544 145.7 529.7 160 512 160L128 160C110.3 160 96 145.7 96 128C96 110.3 110.3 96 128 96L224 96L232.7 69.9zM128 208L512 208L512 512C512 547.3 483.3 576 448 576L192 576C156.7 576 128 547.3 128 512L128 208zM216 272C202.7 272 192 282.7 192 296L192 488C192 501.3 202.7 512 216 512C229.3 512 240 501.3 240 488L240 296C240 282.7 229.3 272 216 272zM320 272C306.7 272 296 282.7 296 296L296 488C296 501.3 306.7 512 320 512C333.3 512 344 501.3 344 488L344 296C344 282.7 333.3 272 320 272zM424 272C410.7 272 400 282.7 400 296L400 488C400 501.3 410.7 512 424 512C437.3 512 448 501.3 448 488L448 296C448 282.7 437.3 272 424 272z"/></svg>
              </button>
            </div>
          </div>
        </div>
        <div class="group h-5">
          <div class="flex flex-row">
            <div class="flex-grow"/>
            <button class="mr-3 text-sm invisible group-hover:visible" phx-click="add-block" phx-value-block-id={block.id}><span class="font-bold">+</span> Insert block</button>
            <div class="flex-grow"/>
          </div>
        </div>
      </div>
    <% end %>
    """
  end

  defp render_request(assigns = %{req: %{ res: nil, lua_result: [nil, err] }}) when is_bitstring(err) do
    # TODO: deze moeten we nog fixen, die assigns zijn hier totaal gefaked!
    ~H"""
      <div class="flex flex-col">
        <div class="flex flex-row-reverse text-xs text-red-700 rounded-b pb-1 px-1">
          <%= format_request(@req)%>: <%= err %>
        </div>
      </div>
    """
  end

  defp render_request(assigns) do
    ~H"""
      <div class="flex flex-col">
        <a class="flex flex-row text-xs rounded-b pb-1 px-1 pt-1 hover:bg-gray-500 hover:bg-opacity-10 transition-colors duration-150"
            href="#" phx-click="select-request" phx-value-block-id={@block_id} phx-value-line_nr={@req.call_info.line_nr} phx-value-request-index={@request_index}>
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
    <a href="#" class="px-1" phx-click="toggle-requests" phx-value-block-id={@block.id}>▲</a>
    """
  end

  defp render_block_stats(assigns) do
    ~H"""
    <%= case Enum.count(@requests) do %>
    <% 0 -> %>
    <% count -> %>
      <a href="#" class="px-1" phx-click="toggle-requests" phx-value-block-id={@block.id}><%=count%> requests ▼</a>
    <% end %>
    """
  end

  defp requests_for_block(requests, block_id) do
    requests[block_id] || []
  end

  defp format_response(nil), do: nil
  defp format_response(assigns) do
     ~H"""
     <span style="color: rgb(50, 138, 50);"  class="rounded font-bold mx-1">
        <%= @res.status %>
      </span>
     """
  end
end
