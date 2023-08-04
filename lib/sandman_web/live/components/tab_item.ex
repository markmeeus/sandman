defmodule SandmanWeb.TabBar do
  use Phoenix.Component
  alias Phoenix.LiveView.JS

  def item(assigns = %{selected: true}) do
    ~H"""
    <a href="#" phx-click={JS.push(@event, value: %{tab: @item})}
      class="border-indigo-500 text-indigo-600 whitespace-nowrap border-b-2 py-2 pr-1 text-xs font-medium" aria-current="page">
      <%= @item %>
    </a>
    """
  end
  def item(assigns = %{selected: false}) do
    ~H"""
    <a href="#" phx-click={JS.push(@event, value: %{tab: @item})}
      class="border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700 whitespace-nowrap border-b-2 py-2 pr-1 text-xs font-medium">
      <%= @item %>
    </a>
    """
  end
end
