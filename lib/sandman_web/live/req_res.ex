defmodule SandmanWeb.LiveView.RequestResponse do
  # In Phoenix v1.6+ apps, the line is typically: use MyAppWeb, :live_view
  use Phoenix.Component
  alias Phoenix.LiveView.JS

  @spec render(any) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
      <div class="text-black font-mono mx-10 p-4 text-xs"
          style="background-color: white"}>
          <div>
          <div class="block">
            <div class="border-b border-gray-200">
              <nav class="-mb-px flex space-x-2" aria-label="Tabs">
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
        <%= case @req_res do %>
          <% nil -> %>
            No request selected
          <% req_res -> %>
            <%= case @tab do %>
              <% "Request" -> %>
                <.request req={@req_res.req} sub_tab={@sub_tab}/>
              <% "Response" -> %>
              <.response res={@req_res.res} sub_tab={@sub_tab}/>
            <%end%>
        <% end %>
      </div>
    """
  end

  def request(assigns) do
      ~H"""
      <div class="flex flex-col mt-4">
        <a href="#" phx-click={toggle_hidden("#request-headers")} >Headers</a>
        <div id="request-headers" class="hidden">
          <%= inspect(@req.headers) %>
        </div>
        <a href="#" phx-click={toggle_hidden("#request-body")} >Body</a>
        <div id="request-body" class="hidden">
          <%= @req.body %>
        </div>
      </div>
      """
  end
  def response(assigns) do
      ~H"""
      <div class="flex flex-col mt-4" >
        <a href="#" phx-click={toggle_hidden("#response-headers")} >Headers</a>
        <div id="response-headers" class="hidden">
          <%= inspect(@res.headers) %>
        </div>
        <a href="#" phx-click={toggle_hidden("#response-body")} >Body</a>
        <div id="response-body" class="hidden">
          <%= inspect(@res.body) %>
        </div>
      </div>
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

end
