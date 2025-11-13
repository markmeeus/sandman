defmodule Sandman.FileAccess.RecentPath do
  @moduledoc """
  Manages the most recently used directory path for the file picker.
  Persists the path to a file so it survives application restarts.
  """

  @recent_path_file Path.join(System.user_home!(), ".sandman_recent_path")

  @doc """
  Gets the most recent directory path, falling back to DEFAULT_FILE_PICKER_PATH
  environment variable or user home directory.
  """
  def get do
    cond do
      # First try to read from persisted file
      File.exists?(@recent_path_file) ->
        case File.read(@recent_path_file) do
          {:ok, path} ->
            path = String.trim(path)
            if File.dir?(path) do
              path
            else
              get_default_path()
            end
          {:error, _} ->
            get_default_path()
        end

      # Fall back to default path
      true ->
        get_default_path()
    end
  end

  @doc """
  Saves a directory path as the most recent path.
  If a file path is provided, extracts the directory.
  """
  def save(path) when is_binary(path) do
    dir_path = if File.dir?(path) do
      path
    else
      Path.dirname(path)
    end

    File.write(@recent_path_file, dir_path)
  end

  defp get_default_path do
    case System.get_env("DEFAULT_FILE_PICKER_PATH") do
      nil ->
        System.user_home!()
      path ->
        if File.dir?(path) do
          path
        else
          System.user_home!()
        end
    end
  end
end

