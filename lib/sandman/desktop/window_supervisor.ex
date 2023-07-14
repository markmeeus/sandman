
defmodule Sandman.WindowSupervisor do

  use DynamicSupervisor

  def start_link(init_args) do
    DynamicSupervisor.start_link(__MODULE__, [init_args], name: __MODULE__)
  end

  def start_child() do
    id = String.to_atom(to_string(:rand.uniform(4294967296)))
    start_options = [
      app: :sandman,
      id: id,
      url: &SandmanWeb.Endpoint.url/0,
      title: "Sandman",
      size: { 1000, 600 },
      menubar: MenuBar
    ]

    child_spec = %{
      id: id,
      start: {Desktop.Window, :start_link, [start_options]},
      restart: :transient,
      shutdown: :brutal_kill,
      type: :worker
    }

    {:ok, pid} = DynamicSupervisor.start_child(__MODULE__, child_spec)
    spawn_link(fn ->
      Process.link(pid)
      Process.flag(:trap_exit, true)
      receive do
        {:EXIT, pid, :normal} ->
          handle_no_windows_left()
          Process.sleep(1000)
          handle_no_windows_left()
      end
    end)
  end

  def init([init_args]) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  defp handle_no_windows_left do
    if (DynamicSupervisor.count_children(__MODULE__).active == 0) do
      # always have a window ?
      # start_child()
      # or shutdown ?
      Desktop.OS.shutdown()
    end
  end
end
