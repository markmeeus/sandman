defmodule SandMan.HttpClient do
  import Sandman.Logger
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
    headers = map_headers(doc_id, headers)
    # TODO: finch build can fail as well
    try do
      Finch.build(method, url, headers, body)
      |> send_request()
    rescue
      e in ArgumentError -> %{
        req: nil,
        res: nil,
        error: e,
        lua_result: [nil, Exception.message(e)]
      }
    end
  end


  defp send_request(req) do
    case Finch.request(req, Sandman.Finch) do
      {:ok, res} ->
        headers = Enum.reduce(res.headers, %{}, fn {k, v}, headers ->
          case headers[k] do
            nil -> Map.put(headers, String.downcase(k), [v])
            arr -> Map.put(headers, String.downcase(k), arr ++ [v])
          end
        end)
        %{
          req: req,
          res: res,
          error: nil,
          lua_result: [LuaMapper.reverse_map(%{
            body: res.body,
            headers: headers,
            status: res.status
          }), nil]
        }

      {:error, exc = %Mint.TransportError{}} ->
        %{
          req: req,
          res: nil,
          error: exc,
          lua_result: [nil, Exception.message(exc)]
        }

      {:error, exc} ->
        %{
          req: req,
          res: nil,
          error: exc,
          lua_result: [nil, inspect(exc)]
        }
      unexpected ->
        %{
          req: req,
          res: nil,
          error: unexpected,
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
