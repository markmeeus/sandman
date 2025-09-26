defmodule SandmanWeb.LiveView.Log do
  # In Phoenix v1.6+ apps, the line is typically: use MyAppWeb, :live_view
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  @spec render(any) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
      <div id="log-bar" class="rounded bg-neutral-700 border border-neutral-600 no-select flex flex-row-reverse text-xs p-2" >
        <button class="mr-2 text-neutral-300 hover:text-neutral-100 px-2 py-1 rounded border border-neutral-500 hover:bg-neutral-600 transition-colors" phx-click={JS.dispatch("clearLog") |> JS.push("clear-log")} >clear</button>
        <div class="grow text-neutral-100 font-medium">Log</div>
      </div>
      <div id="sandman-log" class="text-xs text-neutral-200 flex-1 border-l border-r border-b border-neutral-600 rounded-b bg-neutral-800 flex flex-col min-h-0">
        <div id="log-wrapper" class="font-mono p-2 overflow-auto flex-1 min-h-0">
          <ul id="logs" phx-update="stream">
            <li :for={{dom_id, log} <- @logs} id={dom_id} class="py-0.5 border-b border-neutral-800">
              <%= log.text %>
            </li>
          </ul>
        </div>
      </div>
    """
  end
end
