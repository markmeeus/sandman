defmodule SandMan.HttpClient do
  import Sandman.Logger
  alias Sandman.LuaMapper

  def fetch_handler(doc_id, method, args, luerl_state) do
    {res, err} = args
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
          |> LuaMapper.reverse_map()
          |> case do
            {:error, msg} ->
              {nil, msg}
            res ->
              {res, nil}
          end
    end
    {[res, err], luerl_state}
  end

  def fetch(doc_id, method, url, headers, body) do
    headers = map_headers(doc_id, headers)
    case Finch.build(method_atom(method), url, headers, body) |> IO.inspect |> Finch.request(Sandman.Finch) do
      {:ok, resp} ->
        headers = Enum.reduce(resp.headers, %{}, fn {k, v}, headers ->
          case headers[k] do
            nil -> Map.put(headers, String.downcase(k), [v])
            arr -> Map.put(headers, String.downcase(k), arr ++ [v])
          end
        end)
        %{
          body: resp.body,
          headers: headers,
          status: resp.status
        }
      {:error, exc = %Mint.TransportError{}} ->
        {:error, Exception.message(exc)}

      {:error, exc} -> {:error, inspect(exc)}
      err ->
        IO.inspect("Implement this error and return to lua")
        {:error, inspect(err)}
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

  defp method_atom("get"), do: :get
  defp method_atom("post"), do: :post
  defp method_atom("head"), do: :head
  defp method_atom("patch"), do: :patch
  defp method_atom("delete"), do: :delete
  defp method_atom("options"), do: :options
  defp method_atom("put"), do: :put
end
