defmodule Sandman.NewOrOpen do
  use Phoenix.Component

  def render2(assigns) do
    ~H"""
    <div>
      <div phx-click="new_file">New File</div>
      <div phx-click="open_file">Open File</div>
    </div>
    """
  end

  def render(assigns) do
    ~H"""
    <div class="no-select h-screen flex items-center justify-center">
      <div>
        <h2 class="text-sm font-medium text-gray-500">Create a new file, or open an existing one</h2>
        <ul role="list" class="p-10 mt-3 grid grid-cols-1 gap-5">
          <li class="col-span-1 flex rounded-md shadow-sm" style={"width: 10em;"}>
            <div class="flex flex-1 items-center justify-between truncate rounded-md border-b border-r border-t border-gray-200 bg-white">
              <div class="flex-1 truncate px-4 py-2 text-sm">
                <a href="#" class="font-medium text-gray-900 hover:text-gray-600">
                  <div phx-click="new_file">New File</div>
                </a>
              </div>
            </div>
          </li>
          <li class="col-span-1 flex rounded-md shadow-sm" style={"width: 10em;"}>
            <div class="flex flex-1 items-center justify-between truncate rounded-md border-b border-r border-t border-gray-200 bg-white">
              <div class="flex-1 truncate px-4 py-2 text-sm">
                <a href="#" class="font-medium text-gray-900 hover:text-gray-600">
                  <div phx-click="open_file">Open Existing File</div>
                </a>
              </div>
            </div>
          </li>
        </ul>
      </div>
    </div>
    """
  end
end
