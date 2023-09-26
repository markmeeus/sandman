defmodule SandmanWeb.LiveView.Log do
  # In Phoenix v1.6+ apps, the line is typically: use MyAppWeb, :live_view
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  @spec render(any) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
      <div id="log-bar" class="rounded no-select flex flex-row-reverse text-xs p-1 px-2" >
        <button class="mr-2" phx-click={JS.dispatch("clearLog") |> JS.push("clear-log")} >clear</button>
        <div class="grow">Log</div>
      </div>
      <div id="sandman-log" class="text-xs overflow-contain overflow-scroll flex-1">
        <div id="log-wrapper" class="font-mono p-1">
          <ul id="logs" phx-update="stream">
            <li :for={{dom_id, log} <- @logs} id={dom_id}>
              <%= log.text %>
            </li>
          </ul>
        </div>
      </div>
    """
  end
end
