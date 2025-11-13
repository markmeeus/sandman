defmodule Sandman.FilePicker do
  use Phoenix.Component
  alias SandmanWeb.UpdateBar

  def render(assigns) do
    ~H"""
    <%= live_render(@socket, UpdateBar, id: "update_bar") %>
    <div class="no-select h-screen bg-neutral-900 flex items-center justify-center">
      <div class="w-full max-w-4xl mx-4">
        <div class="bg-neutral-800 rounded-lg shadow-xl border border-neutral-700">
          <!-- Header -->
          <div class="px-6 py-4 border-b border-neutral-700">
            <h2 class="text-lg font-medium text-neutral-100">
              <%= if @mode == :new, do: "Create New File", else: "Open File" %>
            </h2>
            <p class="mt-1 text-sm text-neutral-400">
              <%= if @mode == :new, do: "Choose a location and enter a filename", else: "Browse and select a file" %>
            </p>
          </div>

          <!-- Current Path and Options -->
          <div class="px-6 py-3 bg-neutral-850 border-b border-neutral-700">
            <div class="flex items-center justify-between">
              <div class="flex items-center gap-2 text-sm">
                <svg class="w-4 h-4 text-neutral-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-5l-2-2H5a2 2 0 00-2 2z"></path>
                </svg>
                <span class="text-neutral-300 font-mono"><%= @current_path %></span>
              </div>
              <label class="flex items-center gap-2 text-sm text-neutral-400 hover:text-neutral-300 cursor-pointer">
                <input
                  type="checkbox"
                  phx-click="toggle_hidden_files"
                  checked={@show_hidden}
                  class="rounded border-neutral-600 bg-neutral-700 text-blue-600 focus:ring-2 focus:ring-blue-500 focus:ring-offset-0"
                />
                <span>Show hidden files</span>
              </label>
            </div>
          </div>

          <!-- File Browser -->
          <div id="file-browser-scroll" class="overflow-y-auto" style="max-height: 400px;" phx-hook="ScrollToTop">
            <!-- Parent Directory Link -->
            <%= if @current_path != "/" do %>
              <div
                phx-click="navigate_to_parent"
                class="px-6 py-3 hover:bg-neutral-700 cursor-pointer border-b border-neutral-800 flex items-center gap-3"
              >
                <svg class="w-5 h-5 text-neutral-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18"></path>
                </svg>
                <span class="text-neutral-300">..</span>
              </div>
            <% end %>

            <!-- Directory and File List -->
            <%= for entry <- @entries do %>
              <%= if entry.type == :directory do %>
                <div
                  phx-click="navigate_to_directory"
                  phx-value-path={entry.path}
                  class="px-6 py-3 hover:bg-neutral-700 cursor-pointer border-b border-neutral-800 flex items-center gap-3"
                >
                  <svg class="w-5 h-5 text-blue-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-5l-2-2H5a2 2 0 00-2 2z"></path>
                  </svg>
                  <span class="text-neutral-200"><%= entry.name %></span>
                </div>
              <% else %>
                <div
                  phx-click={if @mode == :open, do: "select_file_from_picker", else: nil}
                  phx-value-path={entry.path}
                  class={"px-6 py-3 border-b border-neutral-800 flex items-center gap-3 #{if @mode == :open, do: "hover:bg-neutral-700 cursor-pointer", else: ""}"}
                >
                  <svg class="w-5 h-5 text-neutral-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path>
                  </svg>
                  <span class="text-neutral-300"><%= entry.name %></span>
                  <span class="text-xs text-neutral-500 ml-auto"><%= entry.size %></span>
                </div>
              <% end %>
            <% end %>

            <%= if @entries == [] do %>
              <div class="px-6 py-8 text-center text-neutral-500">
                <p>No files or directories found</p>
              </div>
            <% end %>
          </div>

          <!-- New File Input (only shown in :new mode) -->
          <%= if @mode == :new do %>
            <div class="px-6 py-4 border-t border-neutral-700 bg-neutral-850">
              <label class="block text-sm font-medium text-neutral-300 mb-2">
                New Filename
              </label>
              <div class="flex gap-2">
                <input
                  type="text"
                  phx-keyup="update_new_filename"
                  phx-keydown="check_enter_key"
                  value={@new_filename}
                  placeholder="my-script.md"
                  class="flex-1 px-3 py-2 bg-neutral-700 border border-neutral-600 rounded text-neutral-100 placeholder-neutral-500 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>
              <%= if @new_filename_error do %>
                <p class="mt-2 text-sm text-red-400"><%= @new_filename_error %></p>
              <% end %>
            </div>
          <% end %>

          <!-- Footer Actions -->
          <div class="px-6 py-4 border-t border-neutral-700 flex items-center justify-between">
            <button
              phx-click="cancel_file_picker"
              class="px-4 py-2 text-sm font-medium text-neutral-300 hover:text-neutral-100 bg-neutral-700 hover:bg-neutral-600 rounded transition-colors"
            >
              Cancel
            </button>

            <%= if @mode == :new do %>
              <button
                phx-click="create_new_file"
                disabled={@new_filename == "" || @new_filename_error}
                class="px-4 py-2 text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 rounded transition-colors disabled:bg-neutral-600 disabled:text-neutral-400 disabled:cursor-not-allowed"
              >
                Create File
              </button>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
