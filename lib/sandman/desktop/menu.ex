defmodule MenuBar do
  use Desktop.Menu, server: false

  @impl true
  def mount(menu) do
    menu = assign(menu, items: [%{name: "item1"}, %{name: "item2"}])
    {:ok, menu}
  end

  @impl true
  def handle_event(command, menu) do
    case command do
      <<"new_window">> -> Sandman.WindowSupervisor.start_child()
      <<"quit">> -> Desktop.Window.quit()
      <<"help">> -> :wx_misc.launchDefaultBrowser('https://google.com')
      <<"about">> -> :not_implemented
    end

    {:noreply, menu}
  end

  @impl true
  def handle_info(_, menu) do
    {:noreply, menu}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <menubar>
      <menu label="File">
          <item onclick="new_window"><%= "New window" %></item>
          <hr/>
          <item onclick="quit"><%= "Quit" %></item>
      </menu>
      <menu label="Help">
          <item onclick="help"><%= "Show Documentation" %></item>
          <item onclick="about"><%= "About" %></item>
      </menu>
    </menubar>
    """
  end
end
