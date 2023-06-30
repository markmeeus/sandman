defmodule Sandman.Encoders.Json do

  alias Sandman.LuaMapper
  import Sandman.Logger

  def decode(doc_id, [json], luerl_state) do
    res = json
      |> Jason.decode
      |> case do
        {:ok, data} ->
          [LuaMapper.reverse_map(data)]
        {:error, err} ->
          message = Jason.DecodeError.message(err)
          :luerl_lib.lua_error({"jJson parse error", message}, luerl_state)
      end
    {res, luerl_state}
  end
  def decode(doc_id, _, luerl_state) do
    log(doc_id, "Unexpected arguments in JSON.decode")
    {[nil, false, "Unexpected arguments in JSON.decode"], luerl_state}
  end

  def encode(_, [data], luerl_state) do
    json = data
    |> LuaMapper.map_unchecked()
    |> Jason.encode!
    {[json], luerl_state}
  end
  def encode(doc_id, _, luerl_state) do
    log(doc_id, "Unexpected arguments in JSON.encode")
    {nil, luerl_state}
  end

end
