defmodule Sandman.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      SandmanWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Sandman.PubSub},
      # Start Finch
      {Finch, name: Sandman.Finch, pools: %{
        default: [conn_opts: [transport_opts: [verify: :verify_none]]] #TODO ohoh, misschien aparte unsecure pool?
      }},
      # Start the Endpoint (http/https)
      SandmanWeb.Endpoint,
      # Start a worker by calling: Sandman.Worker.start_link(arg)
      # {Sandman.Worker, arg}
    ]

    desktop_env = Application.get_env(:sandman, :desktop)
    children = if desktop_env[:open_window] do
      children ++ [{Desktop.Window,
      [
          app: :sandman,
          id: MainApp,
          url: &SandmanWeb.Endpoint.url/0,
          title: "Sandman",
          size: { 1000, 600 },
          menubar: MenuBar
      ]}]
    else
      children
    end
    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Sandman.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    SandmanWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
