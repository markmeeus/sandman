defmodule SandmanWeb.LiveView.Document do
  # In Phoenix v1.6+ apps, the line is typically: use MyAppWeb, :live_view
  use Phoenix.Component

  alias Sandman.Document
  alias Phoenix.PubSub

  def mount(_params, _session, socket) do
    socket = assign(socket, :code, "some code")
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div phx-hook="DocumentHook" id="document">
      <form phx-change="update" phx-hook="TitleForm" id="title-form">
        <input
          type="text"
          id="title"
          name="title"
          value={@document.title || "new script"}
          spellcheck="false"
          autocomplete="off"
          class="w-full border-0 p-0 px-5 font-semibold text-lg mt-2"
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
      <button class="pt-1 text-sm" phx-click="add-block" phx-value-block-id="-">Add Block</button>
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
            <%= for {req, index} <- Enum.with_index(requests_for_block(@requests, block.id)) do%>
              <%= render_request(%{req: req, block_id: block.id, request_index: index}) %>
            <% end %>
          </div>
          <div class="group min-h-5">
            <div class="flex flex-row fs-2 my-2 text-sm sticky">
              <button phx-click="run-block" phx-value-block-id={block.id}><span><%="▶"%></span> Run</button>
              <div class="flex-grow"/>
                <button class="  mr-3 text-sm hidden group-hover:block" phx-click="add-block" phx-value-block-id={block.id}><span class="font-bold">+</span> Insert block</button>
                <button class=" text-sm hidden group-hover:block" phx-click="remove-block" phx-value-block-id={block.id}><span class="font-bold">-</span> Remove block</button>
              <div class="flex-grow"/>
            </div>
          </div>
        </div>
      <% end %>
    """
  end

  defp render_request(assigns = %{req: %{ res: nil, lua_result: [nil, err] }}) when is_bitstring(err) do
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
            <span style="color: rgb(50, 138, 50);background-color: rgb(238, 238, 238);" class="rounded font-bold px-1">
              <%=String.upcase(to_string(@req.req.method))%></span> <span><%= format_request(@req) %></span>
              <.format_response res={@req.res} />
          </div>
        </a>
      </div>
    """
  end

  defp format_request(%{req: nil}), do: "" # this happens with invalid requests. The error should say enough
  defp format_request(%{req: req, res: res}) do
    "#{String.upcase(to_string(req.method))} #{req.scheme}://#{req.host}"
    |> add_port(req.scheme, req.port)
    |> add_path(req.path)
    |> add_query(req.query)
  end

  defp requests_for_block(requests, block_id) do
    requests[block_id] || []
  end

  defp add_port(formatted, :http, 80), do: formatted
  defp add_port(formatted, :https, 443), do: formatted
  defp add_port(formatted, _, port), do: "#{formatted}:#{port}"

  defp add_path(formatted, path), do: "#{formatted}#{path}"

  defp add_query(formatted, nil), do: formatted
  defp add_query(formatted, q), do: "#{formatted}?#{q}"

  defp format_response(nil), do: nil
  defp format_response(assigns) do
     ~H"""
     <span style="color: rgb(50, 138, 50);background-color: rgb(238, 238, 238);"  class="rounded font-bold px-1">
        <%= @res.status %>
      </span>
     """
  end
end
