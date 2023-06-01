defmodule SandmanWeb.LiveView.RequestResponse do
  # In Phoenix v1.6+ apps, the line is typically: use MyAppWeb, :live_view
  use Phoenix.LiveView,
    container: {:div, class: "h-full"}


  @spec render(any) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
      <div class="text-black font-mono mx-10 p-4 text-xs"
          style="background-color: white"}>
          <div>
          <div class="lg:hidden">
            <label for="tabs" class="sr-only">Select a tab</label>
            <!-- Use an "onChange" listener to redirect the user to the selected tab URL. -->
            <select id="tabs" name="tabs" class="block w-full rounded-md border-gray-300 py-2 pl-3 pr-10 text-base focus:border-indigo-500 focus:outline-none focus:ring-indigo-500 sm:text-sm">
              <option selected>Request</option>
              <option>Payload</option>
              <option>Response Headers</option>
              <option>Response Body</option>
              <option>Response Preview</option>
            </select>
          </div>
          <div class="hidden lg:block">
            <div class="border-b border-gray-200">
              <nav class="-mb-px flex space-x-2" aria-label="Tabs">
                <!-- Current: "border-indigo-500 text-indigo-600", Default: "border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700" -->
                <a href="#" class="border-indigo-500 text-indigo-600 whitespace-nowrap border-b-2 py-4 px-1 text-xs font-medium" aria-current="page">
                  Request
                </a>
                <a href="#" class="border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 whitespace-nowrap border-b-2 py-4 px-1 text-xs font-medium">
                  Payload
                </a>
                <a href="#" class="border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 whitespace-nowrap border-b-2 py-4 px-1 text-xs font-medium">
                  Response Headers
                </a>

                <a href="#" class="border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 whitespace-nowrap border-b-2 py-4 px-1 text-xs font-medium">
                  Response Body
                </a>
                <a href="#" class="border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 whitespace-nowrap border-b-2 py-4 px-1 text-xs font-medium">
                  Response Preview
                </a>
                <a href="#" class="border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 whitespace-nowrap border-b-2 py-4 px-1 text-xs font-medium">
                  Timing
                </a>
              </nav>
            </div>
          </div>
        </div>
        <%= @req_res %>
      </div>
    """
  end

  def mount(_params, _session, socket) do
    Process.send_after(self(), :update, 3000)
    IO.inspect("MOUNTED code view")
    req_res = "request and response goes here"
    socket = socket
    |> assign(:req_res, req_res)
    {:ok, socket}
  end

  def handle_info(:update, socket) do
    IO.inspect({"HANDLE UPDATE", connected?(socket)})
    {:noreply, assign(socket, :req_res, "updated req")}
  end
end
