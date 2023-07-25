defmodule Sandman.LuaSupport.Uri do

  alias Sandman.LuaMapper

  import Sandman.Logger

  def parse(doc_id, [uri], luerl_state) do
    uri = URI.parse(uri)
    res = [LuaMapper.reverse_map(%{
      host: uri.host,
      path: uri.path,
      port: uri.port,
      scheme: uri.scheme,
      userinfo: uri.userinfo,
      queryString: uri.query,
      query: URI.decode_query(uri.query)
    } )]
    {res, luerl_state}
  end

  def tostring(doc_id, [url_map], luerl_state) do
    {map, errors} = LuaMapper.map(url_map, %{
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

  def encode(doc_id, [url], luerl_state) do
    {[URI.encode(url)], luerl_state}
  end
  def decode(doc_id, [url], luerl_state) do
    {[URI.decode(url)], luerl_state}
  end

  def encodeComponent(doc_id, [url], luerl_state) do
    res = URI.encode(url, &URI.char_unreserved?(&1))
    {[res], luerl_state}
  end
  def decodeComponent(doc_id, [url], luerl_state) do
    {[URI.decode(url)], luerl_state}
  end

end
