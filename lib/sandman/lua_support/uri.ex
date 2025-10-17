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
    {res, luerl_state}
  end

  def tostring(_doc_id, [url_map], luerl_state) do
    # use query map if querystring is not available
    map = case {url_map[:query_string], url_map[:query]} do
      {nil, nil} -> url_map
      {nil, query} -> Map.put(url_map, :query, URI.encode_query(query))
      {queryString, _} -> Map.put(url_map, :query, queryString)
    end

    uri = struct(%URI{},url_map)
    res = URI.to_string(uri)
    {[res], luerl_state}
  end

  def encode(_doc_id, [url], luerl_state) do
    {[URI.encode(url)], luerl_state}
  end

  def decode(_doc_id, [url], luerl_state) do
      {[URI.decode(url)], luerl_state}
  end

  def encode_component(_doc_id, [url], luerl_state) do
    {[URI.encode(url, &URI.char_unreserved?(&1))], luerl_state}
  end

  def decode_component(_doc_id, [url], luerl_state) do
    {[URI.decode(url)], luerl_state}
  end

end
