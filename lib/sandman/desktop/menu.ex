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
      <<"check_updates">> -> Sandman.UpdateManager.check()
      <<"quit">> -> Desktop.Window.quit()
      <<"help">> -> :wx_misc.launchDefaultBrowser('https://github.com/markmeeus/sandman-docs')
      <<"about">> -> :wx_misc.launchDefaultBrowser('https://sandmanapp.com')
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
          <item onclick="check_updates"><%= "Check For Updates" %></item>
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
