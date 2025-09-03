defmodule Sandman.LuaSupport.Uri do

  alias Sandman.LuaMapper

  def parse(_doc_id, [uri], luerl_state) do
    uri = URI.parse(uri)
    res = [LuaMapper.reverse_map(%{
      host: uri.host,
      path: uri.path,
      port: uri.port,
      scheme: uri.scheme,
      userinfo: uri.userinfo,
      queryString: uri.query,
      query: URI.decode_query(uri.query || "")
    } )]
    :luerl.encode_list(res, luerl_state)
  end

  def tostring(_doc_id, [url_map], luerl_state) do
    decoded_url_map = :luerl.decode(url_map, luerl_state)
    {map, _errors} = LuaMapper.map(decoded_url_map, %{
      "host" => :string,
      "path" => :string,
      "port" => :integer,
      "scheme" => :string,
      "userinfo" => :string,
      "query" => :any,
      "queryString" => :string
    })
    # use query map if querystring is not available
    map = case {map[:query_string], map[:query]} do
      {nil, nil} -> map
      {nil, query} -> Map.put(map, :query, URI.encode_query(query))
      {queryString, _} -> Map.put(map, :query, queryString)
    end
    uri = struct(%URI{}, map)
    res = URI.to_string(uri)
    {[res], luerl_state}
  end

  def encode(_doc_id, [url], luerl_state) do
    :luerl.decode(url, luerl_state)
    |> case do
      url when is_binary(url) ->
        {[URI.encode(url)], luerl_state}
      other ->
        {:luerl_lib.lua_error({"Unexpected param", "expecting string"}, luerl_state), luerl_state}
      end
  end
  def decode(_doc_id, [url], luerl_state) do
    :luerl.decode(url, luerl_state)
    |> case do
      url when is_binary(url) ->
        {[URI.decode(url)], luerl_state}
      other ->
        {:luerl_lib.lua_error({"Unexpected param", "expecting string"}, luerl_state), luerl_state}
      end
  end

  def encodeComponent(_doc_id, [url], luerl_state) do
    :luerl.decode(url, luerl_state)
    |> case do
      url when is_binary(url) ->
        {[URI.encode(url, &URI.char_unreserved?(&1))], luerl_state}
      other ->
        {:luerl_lib.lua_error({"Unexpected param", "expecting string"}, luerl_state), luerl_state}
      end
  end
  def decodeComponent(_doc_id, [url], luerl_state) do
    :luerl.decode(url, luerl_state)
    |> case do
      url when is_binary(url) ->
        {[URI.decode(url)], luerl_state}
      other ->
        {:luerl_lib.lua_error({"Unexpected param", "expecting string"}, luerl_state), luerl_state}
      end
  end

end
