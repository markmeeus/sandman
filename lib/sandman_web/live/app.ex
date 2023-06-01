defmodule SandmanWeb.LiveView.App do
  # In Phoenix v1.6+ apps, the line is typically: use MyAppWeb, :live_view
  use Phoenix.LiveView

  @spec render(any) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <div id="script-log-container">
      <div id="script-container" style="height: calc(50% - 5px);">
        <div
          id="code-editor"
          class="flex w-full h-full"
          phx-hook="CodeEditor"
          phx-update="ignore"
          data-language="lua"
          data-code={@code}
        >
          <div class="w-full h-full" data-el-code-editor />
        </div>
      </div>
      <div id="log-container">
        <textarea id='log'><%= @log %></textarea>:
      </div>
    </div>
    <div id="req-res-container">
      <textarea id='req_res'><%= inspect(@req_res) %></textarea>
    </div>
    <button><%= @code %></button>
    """
  end

  def mount(_params, _session, socket) do
    IO.inspect("MOUNTED")
    Process.send_after(self(), :update, 1000)
    code = "-- your first request\n -- get('http://')"
    log = "GET http://"
    socket = socket
    |> assign(:code, code)
    |> assign(:log, log)
    |> assign(:req_res, nil)
    {:ok, socket}
  end

  def handle_info(:update, socket) do
    IO.inspect({"HANDLE UPDATE", connected?(socket)})
    {:noreply, assign(socket, :code, "update")}
  end
end
