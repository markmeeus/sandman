defmodule SandmanWeb.LiveView.Log do
  # In Phoenix v1.6+ apps, the line is typically: use MyAppWeb, :live_view
  use Phoenix.Component

  alias Phoenix.LiveView.JS
  alias Sandman.Document
  alias Phoenix.PubSub

  @spec render(any) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
      <div id="sandman-log" class="text-black text-xs">
        <div id="log-bar" class="space-x-1 flex flex-row-reverse" style="background-color:#EEE">
          <button class="mr-2" phx-click={JS.dispatch("clearLog") |> JS.push("clear-log")} >clear</button>
          <div class="grow">Log</div>
        </div>
        <div id="log-wrapper" class="font-mono p-2">
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
