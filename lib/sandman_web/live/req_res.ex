defmodule SandmanWeb.LiveView.RequestResponse do
  # In Phoenix v1.6+ apps, the line is typically: use MyAppWeb, :live_view
  use Phoenix.Component
  import Sandman.RequestFormatting
  alias Phoenix.LiveView.JS
  alias Sandman.Document

  @spec render(any) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
      <div class="h-full bg-neutral-800">
        <%= case get_req_res(@requests, @request_id) do %>
          <% nil -> %>
            <div class="flex items-center justify-center h-full">
              <div class="text-center">
                <div class="w-12 h-12 mx-auto mb-3 text-neutral-600">
                  <svg fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 4V2a1 1 0 011-1h8a1 1 0 011 1v2h4a1 1 0 110 2h-1v12a2 2 0 01-2 2H6a2 2 0 01-2-2V6H3a1 1 0 110-2h4zM9 6v10a1 1 0 102 0V6a1 1 0 10-2 0zm4 0v10a1 1 0 102 0V6a1 1 0 10-2 0z"></path>
                  </svg>
                </div>
                <h3 class="text-sm font-medium text-neutral-100 mb-1">No Request Selected</h3>
                <p class="text-xs text-neutral-400">Select a request from the document to view its details</p>
              </div>
            </div>
          <% req_res -> %>
            <div class="flex flex-col h-full">
              <!-- Request Header Section -->
              <div class="bg-neutral-700 border-b border-neutral-600 p-3 shadow-sm flex-shrink-0">
                <div class="flex items-start justify-between">
                  <div class="flex-1 min-w-0">
                    <div class="flex items-center gap-2 mb-1">
                      <.http_method_badge method={req_res.req.method} />
                      <%= if(req_res.res) do %>
                        <.status_badge status={req_res.res.status} />
                      <% end %>
                    </div>
                    <h2 class="text-sm font-medium text-neutral-100 truncate">
                      <%= format_request(req_res) %>
                    </h2>
                  </div>
                </div>
              </div>

              <!-- Tab Navigation -->
              <div class="bg-neutral-700 border-b border-neutral-600 flex-shrink-0">
                <nav class="flex px-3" aria-label="Tabs">
                  <%= Enum.map(["Request", "Response"], fn item -> %>
                    <SandmanWeb.TabBar.item event="switch_tab" item={item} selected={item == @tab}/>
                  <% end) %>
                </nav>
              </div>

              <!-- Content Area -->
              <div class="flex-1 overflow-auto">
                <%= case @tab do %>
                  <% "Request" -> %>
                    <.request doc_pid={@doc_pid} show_raw_body={@show_raw_req_body} request_id={@request_id} is_json={req_res.req_content_info.is_json} req={req_res.req} sub_tab={@sub_tab}/>
                  <% "Response" -> %>
                    <.response doc_pid={@doc_pid} show_raw_body={@show_raw_res_body} request_id={@request_id} is_json={req_res.res_content_info.is_json} res={req_res.res} sub_tab={@sub_tab}/>
                <%end%>
              </div>
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
    <div class="bg-neutral-800">
      <div class="p-3 space-y-3">
        <.toggle_block name="request-headers" title="Headers"
          default_open={false} extra_toggle={nil} />

        <div id="request-headers" class="hidden">
          <.headers headers={@req.headers} />
        </div>

        <.toggle_block name="request-body" title="Body"
          default_open={true}
          extra_toggle={if @show_raw_body, do: "Show Preview", else: "Show Raw"}
          extra_toggle_event="switch_req_body_format" />
      </div>

      <div id="request-body" class="px-3 pb-3">
        <div class="h-96 border border-neutral-200 dark:border-neutral-700 rounded-lg overflow-hidden">
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
    </div>
    """
  end
  def response(assigns) do
    {block_id, request_idx} = assigns.request_id
    assigns = assigns
    |> assign(:block_id, block_id)
    |> assign(:request_idx, request_idx)
    ~H"""
    <div class="bg-neutral-800">
      <div class="p-3 space-y-3">
        <.toggle_block name="response-headers" title="Headers" default_open={false} extra_toggle={nil} />
        <div id="response-headers" class="hidden">
          <.headers headers={@res.headers} />
        </div>

        <.toggle_block name="response-body" title="Body"
          default_open={true}
          extra_toggle={if @show_raw_body, do: "Show Preview", else: "Show Raw"}
          extra_toggle_event="switch_res_body_format" />
      </div>

      <div id="response-body" class="px-3 pb-3">
        <div class="h-96 border border-neutral-200 dark:border-neutral-700 rounded-lg overflow-hidden">
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
    </div>
    """
  end

  def headers(assigns) do
    ~H"""
    <div class="bg-neutral-800 rounded border border-neutral-700 overflow-hidden">
      <div class="overflow-x-auto">
        <table class="min-w-full divide-y divide-neutral-700">
          <thead class="bg-neutral-700">
            <tr>
              <th class="px-2 py-1.5 text-left text-xs font-medium text-neutral-400 uppercase tracking-wider">
                Header
              </th>
              <th class="px-2 py-1.5 text-left text-xs font-medium text-neutral-400 uppercase tracking-wider">
                Value
              </th>
            </tr>
          </thead>
          <tbody class="bg-neutral-800 divide-y divide-neutral-700">
            <%= for {n, v} <- @headers do %>
              <tr class="hover:bg-neutral-700">
                <td class="px-2 py-1.5 text-xs font-medium text-neutral-100 font-mono">
                  <%= n %>
                </td>
                <td class="px-2 py-1.5 text-xs text-neutral-300 font-mono break-all">
                  <%= v %>
                </td>
              </tr>
            <%end%>
          </tbody>
        </table>
      </div>
    </div>
    """
  end

  def body(assigns) do
    ~H"""
    <%= @body %>
    """
  end

  def toggle_block(assigns) do
    ~H"""
    <div class="flex items-center justify-between p-2 bg-neutral-800 rounded border border-neutral-700">
      <button
        type="button"
        phx-click={toggle_hidden("##{@name}")}
        class="flex items-center space-x-1.5 text-xs font-medium text-neutral-100 hover:text-neutral-300 no-select"
      >
        <span class="transition-transform duration-200">
          <%= if @default_open do %>
            <svg id={"#{@name}-open"} class="w-3 h-3 transform rotate-90" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"></path>
            </svg>
            <svg id={"#{@name}-closed"} class="w-3 h-3 hidden" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"></path>
            </svg>
          <% else %>
            <svg id={"#{@name}-open"} class="w-3 h-3 transform rotate-90 hidden" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"></path>
            </svg>
            <svg id={"#{@name}-closed"} class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"></path>
            </svg>
          <% end %>
        </span>
        <span><%= @title %></span>
      </button>

      <%= if @extra_toggle do %>
        <button
          type="button"
          phx-click={JS.push(@extra_toggle_event)}
          class="text-xs font-medium text-neutral-300 hover:text-neutral-100 px-1.5 py-0.5 rounded border border-neutral-600 hover:bg-neutral-700 transition-colors"
        >
          <%= @extra_toggle %>
        </button>
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

  # HTTP Method Badge Component
  def http_method_badge(assigns) do

    {bg_class, text_class} = case String.upcase(to_string(assigns.method)) do
      "GET" -> {"bg-neutral-700", "text-neutral-200"}
      "POST" -> {"bg-neutral-600", "text-neutral-100"}
      "PUT" -> {"bg-neutral-500", "text-white"}
      "PATCH" -> {"bg-neutral-400", "text-neutral-900"}
      "DELETE" -> {"bg-neutral-300", "text-neutral-900"}
      _ -> {"bg-neutral-700", "text-neutral-200"}
    end

    assigns = assign(assigns, :bg_class, bg_class)
    assigns = assign(assigns, :text_class, text_class)

    ~H"""
    <span class={"inline-flex items-center px-1.5 py-0.5 rounded text-xs font-medium #{@bg_class} #{@text_class}"}>
      <%= @method %>
    </span>
    """
  end

  # HTTP Status Badge Component
  def status_badge(assigns) do
    status = assigns.status
    {bg_class, text_class} = cond do
      status >= 200 and status < 300 -> {"bg-green-900", "text-green-200"}
      status >= 300 and status < 400 -> {"bg-blue-900", "text-blue-200"}
      status >= 400 and status < 500 -> {"bg-yellow-900", "text-yellow-200"}
      status >= 500 -> {"bg-red-900", "text-red-200"}
      true -> {"bg-neutral-700", "text-neutral-200"}
    end

    assigns = assign(assigns, :bg_class, bg_class)
    assigns = assign(assigns, :text_class, text_class)

    ~H"""
    <span class={"inline-flex items-center px-1.5 py-0.5 rounded text-xs font-medium #{@bg_class} #{@text_class}"}>
      <%= @status %>
    </span>
    """
  end
end
