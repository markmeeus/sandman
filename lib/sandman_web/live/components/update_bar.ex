defmodule SandmanWeb.UpdateBar do

  use Phoenix.LiveView

  alias Phoenix.PubSub
  alias Sandman.UpdateManager

  def mount(_params, _session, socket) do
    PubSub.subscribe(Sandman.PubSub, "update_manager")
    socket = assign(socket, :status, UpdateManager.get_status())
    {:ok, socket}
  end

  def render(assigns = %{status: :idle}) do
    ~H"""
    """
  end

  def render(assigns) do
    {msg_component, color, allow_dismiss} = case assigns.status do
      :checking -> {"Checking for updates ...", "bg-orange-200", false}
      :update_available -> {update_available(assigns), "bg-green-200", true}
      :no_update -> {"Allready on the latest version. 👍", "bg-gray-200", true}
      :failed -> {"Failed to check for updates, please try again later.", "bg-red-200", true}
    end
    assigns = assigns
    |> assign(:msg_component, msg_component)
    |> assign(:color, color)
    |> assign(:allow_dismiss, allow_dismiss)

    ~H"""
      <div class={"flex items-center gap-x-6 #{@color} px-6 py-2.5 sm:px-3.5 sm:before:flex-1"}>
        <p class="text-sm leading-6 text-black">
          <%= @msg_component %>
        </p>
          <div class="flex flex-1 justify-end">
            <%= if(@allow_dismiss) do %>
              <button type="button" class="-m-3 p-3 focus-visible:outline-offset-[-4px]" phx-click="dismiss">
                <span class="sr-only">Dismiss</span>
                <svg class="h-5 w-5 text-black" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                  <path d="M6.28 5.22a.75.75 0 00-1.06 1.06L8.94 10l-3.72 3.72a.75.75 0 101.06 1.06L10 11.06l3.72 3.72a.75.75 0 101.06-1.06L11.06 10l3.72-3.72a.75.75 0 00-1.06-1.06L10 8.94 6.28 5.22z" />
                </svg>
              </button>
            <% end %>
          </div>
      </div>
    """
  end

  def handle_event("dismiss", _, socket) do
    UpdateManager.set_idle();
    {:noreply, assign(socket, :status, :idle)}
  end

  def handle_info({:update_manager, status}, socket) do
    {:noreply, assign(socket, :status, status)}
  end

  def update_available(assigns) do
    ~H"""
    <a href="#" phx-click="open-download">
      <strong class="font-semibold">Update Available, download now.</strong>
    </a>
  """
  end
end
