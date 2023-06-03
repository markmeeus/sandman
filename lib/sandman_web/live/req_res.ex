defmodule SandmanWeb.LiveView.RequestResponse do
  # In Phoenix v1.6+ apps, the line is typically: use MyAppWeb, :live_view
  use Phoenix.LiveView,
    container: {:div, class: "h-full"}

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

        <%= case @tab do %>
          <% "Request" -> %>
            <.request req={@req_res.req} sub_tab={@sub_tab}/>
          <% "Response" -> %>
          <.response res={@req_res.res} sub_tab={@sub_tab}/>
        <%end%>
      </div>
    """
  end

  def mount(_params, _session, socket) do
    Process.send_after(self(), :update, 3000)
    req_res = %{
      req: %{
        headers: "REQ headers",
        body: "REQ body"
      },
      res: %{
        headers: "RESP headers",
        body: "RESP body"
      },
    }
    socket = socket
    |> assign(:req_res, req_res)
    |> assign(tab: "Response")
    |> assign(sub_tab: "Preview")
    {:ok, socket}
  end

  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    # switching subtab to headers, better to keep separate state
    {:noreply, assign(socket, tab: tab, sub_tab: "Headers")}
  end
  def handle_event("switch_sub_tab", %{"tab" => sub_tab}, socket) do
    {:noreply, assign(socket, sub_tab: sub_tab)}
  end

  def request(assigns) do
      ~H"""
      <div class="flex flex-col mt-4">
        <a href="#" phx-click={toggle_hidden("#request-headers")} >Response</a>
        <div id="request-headers" class="hidden">
          Request headers
        </div>
        <a href="#" phx-click={toggle_hidden("#request-body")} >Body</a>
        <div id="request-body" class="hidden">
          Request body
        </div>
      </div>
      """
  end
  def response(assigns) do
      ~H"""
      <div class="flex flex-col mt-4" >
        <a href="#" phx-click={toggle_hidden("#response-headers")} >Response</a>
        <div id="response-headers" class="hidden">
          Hidden response headers
        </div>
        <a href="#" phx-click={toggle_hidden("#response-body")} >Body</a>
        <div id="response-body" class="hidden">
          Hidden response body
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
