defmodule Sandman.UpdateManager do
  use GenServer

  @finch Sandman.Finch.UpdateManager
  @bucket_url "https://sandmandl.s3.amazonaws.com"
  @bucket_updates_url @bucket_url <> "/updates/"
  @version_info_url @bucket_updates_url <> "version.json"

  def start_link(init_args) do
    GenServer.start_link(__MODULE__, [init_args], name: __MODULE__)
  end

  def init(_args) do
    {:ok, %{}, {:continue, :check_for_updates}}
  end

  def handle_continue(:check_for_updates, state) do
    case get_latest_version_info() do
      {:unavailable, reason} -> IO.inspect("TODO: log reason")
      latest_version_info ->
        current_version = to_string(Application.spec(:sandman, :vsn))
        latest_version = latest_version_info["version"]
        case :verl.compare(latest_version, current_version) do
          :gt ->
            IO.inspect("THERE IS A NEW VERSION: #{latest_version}")
            download_and_verify(latest_version)
          _ -> IO.inspect("Nothing new, carry on")
        end
    end

    {:noreply, state}
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

  defp download_and_verify(version) do
    temp_dir = get_clean_updates_folder
    lib_filename = version_to_filename(version) <> ".zip"
    lib_url = @bucket_updates_url <> lib_filename
    path = Path.join(temp_dir, lib_filename)
    file = File.open!(path, [:write, :exclusive])

    request = Finch.build(:get, lib_url)

    Finch.stream(request, @finch, nil, fn
      {:status, status}, _ ->
        IO.inspect("Download assets status: #{status}")

      {:headers, headers}, _ ->
        IO.inspect("Download assets headers: #{inspect(headers)}")

      {:data, data}, _ ->
        IO.binwrite(file, data)
    end)
    IO.inspect("Downloaded update to #{path}")
    File.close(file)
  end

  defp get_clean_updates_folder do
    application_dir = Application.app_dir(:sandman, "priv")
    temp_dir = Path.join(application_dir, "updates")

    {:ok, _} = File.rm_rf(temp_dir) # delete the directory
    :ok = File.mkdir_p(temp_dir)  # Create the directory if it doesn't exist

    temp_dir
  end

  defp version_to_filename(version) do
    String.replace(version, ".", "_")
  end

end
