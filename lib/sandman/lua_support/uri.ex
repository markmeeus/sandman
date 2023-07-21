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

end
