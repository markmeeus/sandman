defmodule Sandman.Encoders.Base64 do

  def encode(_, [decoded], luerl_state) when is_bitstring(decoded) do
    encoded = Base.encode64(decoded)
    {[encoded], luerl_state}
  end

  def encode_url(_, [decoded], luerl_state) when is_bitstring(decoded) do
    encoded = Base.url_encode64(decoded, padding: false)
    {[encoded], luerl_state}
  end

  def decode(_doc_id, [encoded], luerl_state) when is_bitstring(encoded) do
    case Base.decode64(encoded) do
      {:ok, decoded} ->
        {[decoded], luerl_state}
      _ -> # :error
        {:error,"Invalid base64 string", luerl_state}
    end
  end

  def decode_url(_doc_id, [encoded], luerl_state) when is_bitstring(encoded) do
    case Base.url_decode64(encoded, padding: false) do
      {:ok, decoded} ->
        {[decoded], luerl_state}
      _other -> # :error
        {:error, "Invalid base64 string", luerl_state}
    end
  end

end
