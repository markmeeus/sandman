defmodule Sandman.Encoders.Base64 do

  alias Sandman.LuaMapper
  import Sandman.Logger

  def decode(_doc_id, [encoded], luerl_state) when is_bitstring(encoded) do
    case Base.decode64(encoded) do
      {:ok, decoded} ->
        {[decoded], luerl_state}
      _ -> # :error
        :luerl_lib.lua_error({"Base64 decode error", "Invalid base64 string"}, luerl_state)
    end
  end
  def decode(doc_id, _, luerl_state) do
    log(doc_id, "Unexpected arguments in base64.decode")
    {[nil, false, "Unexpected arguments in base64.decode"], luerl_state}
  end

  def decode_url(_doc_id, [encoded], luerl_state) when is_bitstring(encoded) do
    case Base.url_decode64(encoded, padding: false) do
      {:ok, decoded} ->
        {[decoded], luerl_state}
      other -> # :error
        {:luerl_lib.lua_error({"Base64 decode error", "Invalid base64 string"}, luerl_state), luerl_state}

    end
  end
  def decode_url(doc_id, _, luerl_state) do
    log(doc_id, "Unexpected arguments in base64.decode_url")
    {[nil, false, "Unexpected arguments in base64.decode_url"], luerl_state}
  end

  def encode(_, [decoded], luerl_state) when is_bitstring(decoded) do
    encoded = Base.encode64(decoded)
    {[encoded], luerl_state}
  end
  def encode(doc_id, _, luerl_state) do
    log(doc_id, "Unexpected arguments in base64.encode")
    {nil, luerl_state}
  end

  def encode_url(_, [decoded], luerl_state) when is_bitstring(decoded) do
    encoded = Base.url_encode64(decoded, padding: false)
    {[encoded], luerl_state}
  end
  def encode_url(doc_id, _, luerl_state) do
    log(doc_id, "Unexpected arguments in base64.encode_url")
    {nil, luerl_state}
  end

end
