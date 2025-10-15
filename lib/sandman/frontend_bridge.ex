defmodule Sandman.FrontendBridge do
  def send(type, message) do
    encoded = Jason.encode!(%{"type" => type, "message" => message})
    size = byte_size(encoded)
    size_bytes = <<size::32>>
    IO.binwrite(:stdio, size_bytes <> encoded)

    # Wait for response from frontend
    case IO.read(:stdio, 4) do
      <<response_size::32>> ->
        response = IO.read(:stdio, response_size)
        Jason.decode(response)
      _ ->
        {:error, :invalid_response}
    end
  end
end
