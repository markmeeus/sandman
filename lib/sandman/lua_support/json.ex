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
          {:error, message, luerl_state}
      end
  end

  def encode(_, [data], luerl_state) do
    {[Jason.encode!(data)], luerl_state}
  end


end
