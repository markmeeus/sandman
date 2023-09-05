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
    <div phx-hook="DocumentHook" id="document">
      <div class="group" style="position: relative; top: -8px;">
        <div class="text-white p-2 px-6  flex flex-row fs-2 my-2 text-sm sticky" style="background-color:#1E1E1E;">
          <button phx-click="run-all-blocks"><span><%="▶"%></span> Run All</button>
          <div class="flex-grow"/>
        </div>
      </div>
      <form phx-change="update" phx-hook="TitleForm" id="title-form">
        <input
          type="text"
          id="title"
          name="title"
          value={@document.title || "new script"}
          spellcheck="false"
          autocomplete="off"
          class="w-full border-0 p-0 px-5 font-semibold text-lg mt-2 leading-tight"
        />
      </form>

      <%= case @document.blocks do
        [] -> render_empty_state(assigns)
        _ -> render_blocks(assigns)
      end %>
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
        <div class="my-1 pt-1 pb-1 px-5 border-b-2 no-select">
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
          <div class="group min-h-5">
            <div class="flex flex-row fs-2 my-2 text-sm sticky">
              <button phx-click="run-block" phx-value-block-id={block.id}><span><%="▶"%></span> Run</button>
              <div class="flex-grow"/>
              <button class="  mr-3 text-sm hidden group-hover:block" phx-click="add-block" phx-value-block-id={block.id}><span class="font-bold">+</span> Insert block</button>
              <button class=" text-sm hidden group-hover:block" phx-click="remove-block" phx-value-block-id={block.id}><span class="font-bold">-</span> Remove block</button>
              <div class="flex-grow"/>
              <%= render_block_stats(%{requests: requests_for_block(@requests, block.id), block: block, is_open: !!@open_requests[block.id]}) %>
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
        <div class="flex flex-row-reverse text-xs text-red-700 rounded-b pb-1 px-1" style="background-color: rgb(238, 238, 238);">
          <%= format_request(@req)%>: <%= err %>
        </div>
      </div>
    """
  end

  defp render_request(assigns) do
    ~H"""
      <div class="flex flex-col">
        <a class="flex flex-row-reverse text-xs rounded-b pb-1 px-1 pt-1" style="background-color: rgb(238, 238, 238);"
            href="#" phx-click="select-request" phx-value-block-id={@block_id} phx-value-request-index={@request_index}>
          <div >
            <span><%= format_request(@req) %></span>
            <.format_response res={@req.res} />
          </div>
        </a>
      </div>
    """
  end

  defp render_block_stats(assigns = %{is_open: true}) do
    ~H"""
    <a href="#" class="px-1" phx-click="toggle-requests" phx-value-block-id={@block.id}>close ▲</a>
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
     <span style="color: rgb(50, 138, 50);background-color: rgb(238, 238, 238);"  class="rounded font-bold px-1">
        <%= @res.status %>
      </span>
     """
  end
end
