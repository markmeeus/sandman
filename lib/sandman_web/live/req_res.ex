defmodule SandmanWeb.LiveView.RequestResponse do
  # In Phoenix v1.6+ apps, the line is typically: use MyAppWeb, :live_view
  use Phoenix.Component
  import Sandman.RequestFormatting
  alias Phoenix.LiveView.JS
  alias Sandman.Document

  @spec render(any) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
      <div class="text-black font-mono mx-2 p-2 text-xs h-full"
          style="background-color: white"}>
        <div>
      </div>
        <%= case get_req_res(@requests, @request_id) do %>
          <% nil -> %>
            <div class="no-select">No request selected</div>
          <% req_res -> %>
            <div class="block h-full">
              <div class="text-base font-semibold">
                <div class="inline-block bg-gray-100 rounded-lg px-3 py-2">
                  <span><%= format_request(req_res) %></span>
                </div>
                <div class="inline-block bg-green-400 rounded-lg px-3 py-1">
                  <span><%= req_res.res.status %></span>
                </div>
              </div>
              <div class="border-b border-gray-200 mt-2">
                <nav class="-mb-px flex space-x-2 no-select" aria-label="Tabs">
                  <%= Enum.map(["Request", "Response"], fn item -> %>
                    <SandmanWeb.TabBar.item event="switch_tab" item={item} selected={item == @tab}/>
                  <% end) %>
                </nav>
              </div>
              <%= case @tab do %>
                <% "Request" -> %>
                  <.request doc_pid={@doc_pid} show_raw_body={@show_raw_req_body} request_id={@request_id} is_json={req_res.req_content_info.is_json} req={req_res.req} sub_tab={@sub_tab}/>
                <% "Response" -> %>
                  <.response doc_pid={@doc_pid} show_raw_body={@show_raw_res_body} request_id={@request_id} is_json={req_res.res_content_info.is_json} res={req_res.res} sub_tab={@sub_tab}/>
              <%end%>
            </div>
        <% end %>
      </div>
    """
  end

  def request(assigns) do
    {block_id, request_idx} = assigns.request_id
    assigns = assigns
    |> assign(:block_id, block_id)
    |> assign(:request_idx, request_idx)

    ~H"""
    <div class="flex flex-col mt-4 h-full">
      <.toggle_block name="request-headers" title="Headers"
        default_open={false} extra_toggle={nil} />

      <div id="request-headers" class="hidden">
        <.headers headers={@req.headers} />
      </div>

      <.toggle_block name="request-body" title="Body"
        default_open={true}
        extra_toggle={if @show_raw_body, do: "Show Preview", else: "Show Raw"}
        extra_toggle_event="switch_req_body_format" />
      <div id="request-body" class="pt-2">
        <%= if @show_raw_body do %>
          <iframe id="raw" class="h-full w-full" src={"/#{Base.url_encode64(:erlang.term_to_binary(@doc_pid))}/#{@block_id}/request/#{@request_idx}?raw=true"}>
            </iframe>
        <% else %>
          <%= if @is_json do %>
            <iframe id="no-sandbox" class="h-full w-full" src={"/#{Base.url_encode64(:erlang.term_to_binary(@doc_pid))}/#{@block_id}/request/#{@request_idx}"}>
            </iframe>
          <% else %>
            <iframe id="sandbox" sandbox class="h-full w-full" src={"/#{Base.url_encode64(:erlang.term_to_binary(@doc_pid))}/#{@block_id}/request/#{@request_idx}"}>
            </iframe>
          <% end %>
        <% end %>
      </div>
    </div>
    """
  end
  def response(assigns) do
    {block_id, request_idx} = assigns.request_id
    assigns = assigns
    |> assign(:block_id, block_id)
    |> assign(:request_idx, request_idx)
    ~H"""
    <div class="flex flex-col mt-4 h-full" >
      <.toggle_block name="response-headers" title="Headers" default_open={false} extra_toggle={nil} />
      <div id="response-headers" class="hidden">
        <.headers headers={@res.headers} />
      </div>

      <.toggle_block name="response-body" title="Body"
        default_open={true}
        extra_toggle={if @show_raw_body, do: "Show Preview", else: "Show Raw"}
        extra_toggle_event="switch_res_body_format" />
      <div id="response-body" class="pt-2 h-full">
        <%= if @show_raw_body do %>
          <iframe id="raw" class="h-full w-full" src={"/#{Base.url_encode64(:erlang.term_to_binary(@doc_pid))}/#{@block_id}/response/#{@request_idx}?raw=true"}>
            </iframe>
        <% else %>
          <%= if @is_json do %>
            <iframe id="no-sandbox" class="h-full w-full" src={"/#{Base.url_encode64(:erlang.term_to_binary(@doc_pid))}/#{@block_id}/response/#{@request_idx}"}>
            </iframe>
          <% else %>
            <iframe id="sandbox" sandbox class="h-full w-full" src={"/#{Base.url_encode64(:erlang.term_to_binary(@doc_pid))}/#{@block_id}/response/#{@request_idx}"}>
            </iframe>
          <% end %>
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

  def toggle_block(assigns) do
    ~H"""
    <div class="flex flex-row rounded px-2 py-1 my-1" style="background-color:#EEE" >
        <a href="#" phx-click={toggle_hidden("##{@name}")}
          class="no-select "><%=@title%>
            <%= if @default_open do%>
              <span id={"#{@name}-open"}>▼</span>
              <span id={"#{@name}-closed"} class="hidden">▲</span>
            <% else %>
              <span id={"#{@name}-open"} class="hidden">▼</span>
              <span id={"#{@name}-closed"} >▲</span>
            <% end %>
        </a>
        <%= if(@extra_toggle) do %>
          <a href="#" phx-click={JS.push(@extra_toggle_event)}>&nbsp;(<%=@extra_toggle%>)</a>
        <% end %>

      </div>
    """
  end

  def toggle_hidden(js \\ %JS{}, el) do
    js
    |> JS.remove_class(
      "hidden",
      to: "#{el}.hidden"
    )
    |> JS.remove_class(
      "hidden",
      to: "#{el}-open.hidden"
    )
    |> JS.remove_class(
      "hidden",
      to: "#{el}-closed.hidden"
    )
    |> JS.add_class(
      "hidden",
      to: "#{el}:not(.hidden)"
    )
    |> JS.add_class(
      "hidden",
      to: "#{el}-open:not(.hidden)"
    )
    |> JS.add_class(
      "hidden",
      to: "#{el}-closed:not(.hidden)"
    )
  end

  def get_req_res(_, nil), do: nil
  def get_req_res(requests, request_id) do
    Document.get_request_by_id(requests, request_id)
  end
end
