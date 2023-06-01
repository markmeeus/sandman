defmodule SandmanWeb.LiveView.Code do
  # In Phoenix v1.6+ apps, the line is typically: use MyAppWeb, :live_view
  use Phoenix.LiveView,
    container: {:div, class: "h-full"}


  @spec render(any) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
      <div id="script-group" class="h-full">
        <p> Some Markdown </p>
        <div
          id="code-editor"
          class="flex "
          phx-hook="CodeEditor"
          phx-update="ignore"
          data-language="lua"
          data-code={@code}
        >
          <div class="w-full h-full" data-el-code-editor />
        </div>
      </div>
    """
  end

  def mount(_params, _session, socket) do
    IO.inspect("MOUNTED code view")
    code = "-- your first request\n -- get('http://')"
    socket = socket
    |> assign(:code, code)
    {:ok, socket}
  end

  def handle_info(:update, socket) do
    IO.inspect({"HANDLE UPDATE", connected?(socket)})
    {:noreply, assign(socket, :code, "update")}
  end
end
