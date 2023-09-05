defmodule Sandman.UpdateManager do
  use GenServer

  @finch Sandman.Finch.UpdateManager
  @bucket_url "https://sandmandl.s3.amazonaws.com"
  @bucket_updates_url @bucket_url <> "/updates/"
  @version_info_url @bucket_updates_url <> "version.json"

  alias Phoenix.PubSub

  def start_link(init_args) do
    GenServer.start_link(__MODULE__, [init_args], name: __MODULE__)
  end

  def check() do
    GenServer.cast(__MODULE__, :check)
  end

  def get_status() do
    GenServer.call(__MODULE__, :get_status)
  end

  def init(_args) do
    {:ok, %{
      status: :idle
    }, {:continue, :check_for_updates}}
  end

  def handle_continue(:check_for_updates, state) do
    # currently not auto checking
    {:noreply, state}
    #{:noreply, %{ state | status: check_for_update()}}
  end

  def handle_cast(:check, state) do
    {:noreply, %{ state | status: check_for_update()}}
  end

  def handle_call(:get_status, _sender, state = %{status: status}) do
    {:reply, status, state}
  end

  defp check_for_update() do
    PubSub.broadcast(Sandman.PubSub, "update_manager", {:update_manager, :checking})
    Process.sleep(1000)
    status = case get_latest_version_info() do
      {:unavailable, _reason} -> :failed
      latest_version_info ->
        current_version = to_string(Application.spec(:sandman, :vsn))
        latest_version = latest_version_info["version"]
        case :verl.compare(latest_version, current_version) do
          :gt ->
            :update_available
          _ ->
            :no_update
        end
    end
    PubSub.broadcast(Sandman.PubSub, "update_manager", {:update_manager, status})
    status
  end

  defp get_latest_version_info do
    case Finch.build(:get, @version_info_url) |> Finch.request(@finch) do
      {:ok, %Finch.Response{status: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, version_info} -> version_info
          other -> {:unavailable, other}
        end
      other -> {:unavailable, other}
    end
  end
end
