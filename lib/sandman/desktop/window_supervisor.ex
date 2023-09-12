
defmodule Sandman.WindowSupervisor do

  use DynamicSupervisor

  def start_link(init_args) do
    DynamicSupervisor.start_link(__MODULE__, [init_args], name: __MODULE__)
  end

  def start_child() do
    IO.inspect({"SANDMAN ARGS", System.get_env("SANDMAN_ARGS")})
    file_to_load = System.get_env("SANDMAN_ARGS") # TODO, implement proper command line options

    id = String.to_atom(to_string(:rand.uniform(4294967296)))
    start_options = [
      app: :sandman,
      id: id,
      url: fn ->
        URI.append_query(URI.parse(SandmanWeb.Endpoint.url()), URI.encode_query(%{file: file_to_load})) |> URI.to_string
        |> IO.inspect
      end,
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
        {:EXIT, _pid, :normal} ->
          handle_no_windows_left()
          Process.sleep(1000)
          handle_no_windows_left()
      end
    end)
  end

  def init([_init_args]) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  defp handle_no_windows_left do
    if (has_no_windows()) do
      # always have a window ?
      # start_child()
      # or shutdown ?
      Desktop.OS.shutdown()
    end
  end

  defp has_no_windows do
    DynamicSupervisor.count_children(__MODULE__).active == 0
  end
end
