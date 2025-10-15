defmodule Sandman.Encoders.Json do

  def decode(_doc_id, [json], luerl_state) do
    json
      |> Jason.decode
      |> case do
        {:ok, decoded} ->
          {[decoded], luerl_state}
        {:error, err} ->
          message = Jason.DecodeError.message(err)
          {:error, message, luerl_state}
      end
  end

  def encode(_, [data], luerl_state) do
    {[Jason.encode!(data)], luerl_state}
  end


end
