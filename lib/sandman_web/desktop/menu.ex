defmodule MenuBar do
  use Desktop.Menu

  @impl true
  def mount(menu) do
    menu = assign(menu, items: [%{name: "item1"}, %{name: "item2"}])
    {:ok, menu}
  end

  @impl true
  def handle_event(command, menu) do
    case command do
      <<"open">> -> :not_implemented
      <<"quit">> -> Desktop.Window.quit()
      <<"help">> -> :wx_misc.launchDefaultBrowser('https://google.com')
      <<"about">> -> :not_implemented
    end

    {:noreply, menu}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <menubar>
      <menu label="File">
          <item onclick="open"><%= "Open" %></item>
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
