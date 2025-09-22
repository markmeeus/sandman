defmodule Sandman.Encoders.Json do

  alias Sandman.LuaMapper
  import Sandman.Logger

  def decode(_doc_id, [json], luerl_state) do
    json
      |> Jason.decode
      |> case do
        {:ok, data} ->
          mapped = LuaMapper.reverse_map(data)
           {encoded, luerl_state} = :luerl.encode(mapped, luerl_state)
          {[encoded], luerl_state}
        {:error, err} ->
          message = Jason.DecodeError.message(err)
          {:luerl_lib.lua_error({"Json parse error", message}, luerl_state), luerl_state}
      end
  end

  def encode(_, [data], luerl_state) do
    decoded_data = :luerl.decode(data, luerl_state)
    json = decoded_data
    |> LuaMapper.map_unchecked()
    |> Jason.encode!
    {[json], luerl_state}
  end


end
