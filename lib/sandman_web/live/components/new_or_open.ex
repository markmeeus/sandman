defmodule Sandman.NewOrOpen do
  use Phoenix.Component
  alias SandmanWeb.UpdateBar

  def render(assigns) do
    ~H"""
    <%= live_render(@socket, UpdateBar, id: "update_bar") %>
    <div class="no-select h-screen bg-neutral-900 flex items-center justify-center">
      <div>
        <h2 class="text-sm font-medium text-neutral-400 text-center mb-8">Create a new file, or open an existing one</h2>
        <ul role="list" class="grid grid-cols-1 gap-4">
          <li class="col-span-1 flex rounded-lg shadow-sm">
            <div class="flex flex-1 items-center justify-between truncate rounded-lg border border-neutral-700 bg-neutral-800 hover:bg-neutral-700 transition-colors">
              <div class="flex-1 truncate px-6 py-4 text-sm">
                <a href="#" class="font-medium text-neutral-100 hover:text-neutral-300">
                  <div phx-click="new_file" class="flex items-center gap-2">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path>
                    </svg>
                    New File
                  </div>
                </a>
              </div>
            </div>
          </li>
          <li class="col-span-1 flex rounded-lg shadow-sm">
            <div class="flex flex-1 items-center justify-between truncate rounded-lg border border-neutral-700 bg-neutral-800 hover:bg-neutral-700 transition-colors">
              <div class="flex-1 truncate px-6 py-4 text-sm">
                <a href="#" class="font-medium text-neutral-100 hover:text-neutral-300">
                  <div phx-click="open_file" class="flex items-center gap-2">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-5l-2-2H5a2 2 0 00-2 2z"></path>
                    </svg>
                    Open Existing File
                  </div>
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
