defmodule SandmanWeb.LiveView.Runner do
  # In Phoenix v1.6+ apps, the line is typically: use MyAppWeb, :live_view
  use Phoenix.LiveView,
    container: {:div, class: "h-full"}


  @spec render(any) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
      <div id="sandman-log" phx-hook="RunnerHook" class="h-full text-white font-mono" style="background-color: #1E1E1E"}>
        <%= @log %>
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
