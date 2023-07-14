
defmodule Sandman.WindowSupervisor do

  use DynamicSupervisor

  def start_link(init_args) do
    DynamicSupervisor.start_link(__MODULE__, [init_args], name: __MODULE__)
  end

  def start_child(extra_options) do
    id = String.to_atom(to_string(:rand.uniform(4294967296)))
    start_options = Keyword.merge([
      app: :sandman,
      id: id,
      url: &SandmanWeb.Endpoint.url/0,
      title: "Sandman",
      size: { 1000, 600 },
      #menubar: MenuBar
    ], extra_options)

    child_spec = %{
      id: id,
      start: {Desktop.Window, :start_link, [start_options]},
      restart: :transient,
      shutdown: :brutal_kill,
      type: :worker
    }

    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  def init([init_args]) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
