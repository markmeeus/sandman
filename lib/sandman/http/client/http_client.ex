defmodule Sandman.HttpClient do
  import Sandman.Logger
  import Sandman.Http.Helpers
  alias Sandman.LuaMapper

  def fetch_handler(doc_id, method, args, luerl_state) do
    result = args
    |> case  do
      [url] -> [doc_id, method, url, [], nil]
      [url, headers] -> [doc_id, method, url, headers, nil]
      [url, headers, body] -> [doc_id, method, url, headers, body]
      _ -> {:error, "unexpected number of parameters for http.#{method}."}
    end
    |> case do
      {:error, msg} ->
        log(doc_id, msg)
        {nil, msg}
      args ->
        :erlang.apply(__MODULE__, :fetch, args)
    end
    {result, luerl_state}
  end

  def fetch(doc_id, method, url, headers, body) do
    IO.inspect({"unmapped headers", headers})
    headers = map_headers(doc_id, headers)
    IO.inspect({"mapped headers", headers})
    # TODO: finch build can fail as well
    try do
      req = Finch.build(method, url, headers, body)
      send_request(req)
    rescue
      e in ArgumentError -> %{
        req: nil,
        res: nil,
        req_content_info: %{},
        error: e,
        lua_result: [nil, Exception.message(e)]
      }
    end
  end

  defp send_request(req) do
    req_content_info = get_content_info_from_headers(req.headers)
    case Finch.request(req, Sandman.Finch) do
      {:ok, res} ->
        headers = Enum.reduce(res.headers, %{}, fn {k, v}, headers ->
          case headers[k] do
            nil -> Map.put(headers, String.downcase(k), v)
            header -> Map.put(headers, String.downcase(k), "#{header}, #{v}")
          end
        end)

        res_content_info = get_content_info_from_headers(res.headers)
        %{
          req: req,
          res: res,
          req_content_info: req_content_info,
          res_content_info: res_content_info,
          error: nil,
          direction: :out,
          lua_result: [LuaMapper.reverse_map(%{
            "body" => res.body,
            "headers" => headers,
            "status" => res.status
          }), nil]
        }

      {:error, exc = %Mint.TransportError{}} ->
        %{
          req: req,
          req_content_info: req_content_info,
          res_content_info: %{},
          res: nil,
          error: exc,
          direction: :out,
          lua_result: [nil, Exception.message(exc)]
        }

      {:error, exc} ->
        %{
          req: req,
          res: nil,
          req_content_info: req_content_info,
          res_content_info: %{},
          error: exc,
          direction: :out,
          lua_result: [nil, inspect(exc)]
        }
      unexpected ->
        %{
          req: req,
          res: nil,
          req_content_info: req_content_info,
          res_content_info: %{},
          error: unexpected,
          direction: :out,
          lua_result: [nil, "unexpected Finch result (you should not see this):" <> inspect(unexpected)]
        }
    end
  end

  defp map_headers(doc_id, headers) do
    case LuaMapper.map(headers, %{
      :any => fn
        list when is_list(list) -> [:string]
        _ -> :string
        end
    }) do
      {headers, []} -> headers
      {headers, warnings} ->
        log(doc_id, LuaMapper.format(warnings))
        headers
    end
    |> Enum.reduce([], fn
      {key, val}, acc when is_bitstring(val) ->
        acc ++ [{key, val}]
      {key, val}, acc when is_list(val) ->
        # val is list of strings => prepend to acc
        acc ++ Enum.map(val, fn item -> {key, item} end)
    end)
  end
end
