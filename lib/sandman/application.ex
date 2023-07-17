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
      Sandman.WindowSupervisor,
      # Start a worker by calling: Sandman.Worker.start_link(arg)
      # {Sandman.Worker, arg}
    ]
    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Sandman.Supervisor]
    res = Supervisor.start_link(children, opts)

    # start the first window with menu bar
    desktop_env = Application.get_env(:sandman, :desktop)
    children = if desktop_env[:open_window] do # not in test for instance
      Sandman.WindowSupervisor.start_child()
    end
    # return the supervisor ret value
    res
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    SandmanWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
