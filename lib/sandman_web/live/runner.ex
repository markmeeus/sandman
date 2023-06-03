defmodule SandmanWeb.LiveView.Runner do
  # In Phoenix v1.6+ apps, the line is typically: use MyAppWeb, :live_view
  use Phoenix.LiveView,
    container: {:div, class: "h-full"}


  @spec render(any) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
      <div id="sandman-log" phx-hook="RunnerHook" class="text-black font-mono text-xs">
        <div id="log-bar" class="space-x-1 flex flex-row-reverse" style="background-color:#EEE">
          <button class="m-1 p-0.1 px-1 border-2 rounded" style="border-color: #CCC;">clear</button>
          <div class="grow m-2 text-sm">Log</div>
        </div>
        <div id="log-wrapper" class="p-2">
          <%= @log %>
        </div>
      </div>
    """
  end

  def mount(_params, _session, socket) do
    Process.send_after(self(), :update, 3000)
    IO.inspect("MOUNTED code view")
    log = "-- your first request\n -- get('http://')"
    socket = socket
    |> assign(:log, log)
    {:ok, socket}
  end

  def handle_info(:update, socket) do
    IO.inspect({"HANDLE UPDATE", connected?(socket)})
    {:noreply, assign(socket, :log, "update")}
  end

  def handle_event("run-block", params, socket) do
    {:noreply, assign(socket, :log, inspect(params))}
  end
end
