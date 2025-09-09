defmodule SandmanWeb.TabBar do
  use Phoenix.Component
  alias Phoenix.LiveView.JS

  def item(assigns = %{selected: true}) do
    ~H"""
    <button
      type="button"
      phx-click={JS.push(@event, value: %{tab: @item})}
      class="relative px-3 py-2 text-xs font-medium text-neutral-100 bg-neutral-600 border-b-2 border-neutral-100 whitespace-nowrap transition-colors"
      aria-current="page"
    >
      <%= @item %>
    </button>
    """
  end

  def item(assigns = %{selected: false}) do
    ~H"""
    <button
      type="button"
      phx-click={JS.push(@event, value: %{tab: @item})}
      class="relative px-3 py-2 text-xs font-medium text-neutral-400 hover:text-neutral-200 hover:bg-neutral-600/50 border-b-2 border-transparent hover:border-neutral-400 whitespace-nowrap transition-colors"
    >
      <%= @item %>
    </button>
    """
  end
end
