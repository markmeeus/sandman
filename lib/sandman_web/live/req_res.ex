defmodule SandmanWeb.LiveView.RequestResponse do
  # In Phoenix v1.6+ apps, the line is typically: use MyAppWeb, :live_view
  use Phoenix.Component

  alias Phoenix.LiveView.JS
  alias Sandman.Document

  @spec render(any) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
      <div class="text-black font-mono mx-2 p-2 text-xs h-full"
          style="background-color: white"}>
          <div>
          <div class="block">
            <div class="border-b border-gray-200">
              <nav class="-mb-px flex space-x-2 no-select" aria-label="Tabs">
                <%= Enum.map(["Request", "Response"], fn item -> %>
                  <SandmanWeb.TabBar.item event="switch_tab" item={item} selected={item == @tab}/>
                <% end) %>
              </nav>
            </div>
          </div>
        </div>
        <%!-- <nav class="-mb-px flex space-x-2" aria-label="Tabs">
          <%= if @tab == "Request" do %>
            <%= Enum.map(["Headers", "Body"], fn item -> %>
              <SandmanWeb.TabBar.item event="switch_sub_tab" item={item} selected={item == @sub_tab}/>
            <% end) %>
          <% end %>
          <%= if @tab == "Response" do %>
            <%= Enum.map(["Headers", "Body", "Preview"], fn item -> %>
              <SandmanWeb.TabBar.item event="switch_sub_tab" item={item} selected={item == @sub_tab}/>
            <% end) %>
          <% end %>
        </nav> --%>
        <%= case get_req_res(@requests, @request_id) do %>
          <% nil -> %>
            <div class="no-select">No request selected</div>
          <% req_res -> %>
            <%= case @tab do %>
              <% "Request" -> %>
                <.request doc_pid={@doc_pid} request_id={@request_id} is_json={req_res.req_content_info.is_json} req={req_res.req} sub_tab={@sub_tab}/>
              <% "Response" -> %>
                <.response doc_pid={@doc_pid} request_id={@request_id} is_json={req_res.res_content_info.is_json} res={req_res.res} sub_tab={@sub_tab}/>
            <%end%>
        <% end %>
      </div>
    """
  end

  def request(assigns) do
    {block_id, request_idx} = assigns.request_id
    ~H"""
    <div class="flex flex-col mt-4 h-full">
      <a href="#" phx-click={toggle_hidden("#request-headers")} class="no-select rounded px-2 py-1"
        style="background-color:#EEE">Headers</a>
      <div id="request-headers" class="pt-2">
        <.headers headers={@req.headers} />
      </div>
      <a href="#" phx-click={toggle_hidden("#request-body")} class="no-select rounded mt-2 px-2 py-1"
        style="background-color:#EEE">Body</a>
      <div id="request-body" class="pt-2">
        <%= if @is_json do %>
          <iframe id="no-sandbox" class="h-full w-full" src={"http://localhost:7000/#{Base.url_encode64(:erlang.term_to_binary(@doc_pid))}/#{block_id}/request/#{request_idx}"}>
          </iframe>
        <% else %>
          <iframe id="sandbox" sandbox class="h-full w-full" src={"http://localhost:7000/#{Base.url_encode64(:erlang.term_to_binary(@doc_pid))}/#{block_id}/request/#{request_idx}"}>
          </iframe>
        <% end %>
      </div>
    </div>
    """
  end
  def response(assigns) do
    {block_id, request_idx} = assigns.request_id
    ~H"""
    <div class="flex flex-col mt-4 h-full" >
      <a href="#" phx-click={toggle_hidden("#response-headers")} class="no-select rounded px-2 py-1" style="background-color:#EEE" >Headers</a>
      <div id="response-headers" class="pt-2">
        <.headers headers={@res.headers} />
      </div>
      <a href="#" phx-click={toggle_hidden("#response-body")} class="no-select rounded mt-2 px-2 py-1" style="background-color:#EEE">Body</a>
      <div id="response-body" class="pt-2 h-full">
        <%= if @is_json do %>
          <iframe id="no-sandbox" class="h-full w-full" src={"http://localhost:7000/#{Base.url_encode64(:erlang.term_to_binary(@doc_pid))}/#{block_id}/response/#{request_idx}"}>
          </iframe>
        <% else %>
          <iframe id="sandbox" sandbox class="h-full w-full" src={"http://localhost:7000/#{Base.url_encode64(:erlang.term_to_binary(@doc_pid))}/#{block_id}/response/#{request_idx}"}>
          </iframe>
        <% end %>

      </div>
    </div>
    """
  end

  def headers(assigns) do
    ~H"""
    <table class="table-fixed">
      <tbody>
        <%= for {n, v} <- @headers do %>
          <tr class="border-2">
            <td class="border-r-2 px-2"><%= n %><span style="color:transparent">:</span></td>
            <td class="px-4"><%= v %></td>
          </tr>
        <%end%>
      </tbody>
    </table>
    """
  end

  def body(assigns) do
    ~H"""
    <%= @body %>
    """
  end

  def toggle_hidden(js \\ %JS{}, el) do
    js
    |> JS.remove_class(
      "hidden",
      to: "#{el}.hidden"
    )
    |> JS.add_class(
      "hidden",
      to: "#{el}:not(.hidden)"
    )
  end

  def get_req_res(_, nil), do: nil
  def get_req_res(requests, request_id) do
    Document.get_request_by_id(requests, request_id)
  end
end
