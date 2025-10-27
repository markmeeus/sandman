defmodule Sandman.DotEnvLoader do
  @moduledoc """
  Parses .env file content and returns a map of key-value pairs.

  Lines that don't follow the `KEY=VALUE` format are ignored.
  Empty strings return empty maps.
  """

  @doc """
  Parses a string containing environment variables in .env format.

  ## Examples

      iex> Sandman.DotEnvLoader.parse("")
      %{}

      iex> Sandman.DotEnvLoader.parse("KEY=value")
      %{"KEY" => "value"}

      iex> Sandman.DotEnvLoader.parse("KEY1=value1\\nKEY2=value2")
      %{"KEY1" => "value1", "KEY2" => "value2"}

      iex> Sandman.DotEnvLoader.parse("KEY=value\\ninvalid line\\nKEY2=value2")
      %{"KEY" => "value", "KEY2" => "value2"}
  """
  @spec parse(String.t()) :: %{String.t() => String.t()}
  def parse(content) when is_binary(content) do
    content
    |> String.split("\n")
    |> Enum.reduce(%{}, fn line, acc ->
      case parse_line(line) do
        {key, value} -> Map.put(acc, key, value)
        nil -> acc
      end
    end)
  end

  # Parses a single line and returns a tuple of {key, value} or nil if invalid.
  @spec parse_line(String.t()) :: {String.t(), String.t()} | nil
  defp parse_line(line) do
    case String.split(line, "=", parts: 2) do
      [key, value] when key != "" -> {key, value}
      _ -> nil
    end
  end
end
