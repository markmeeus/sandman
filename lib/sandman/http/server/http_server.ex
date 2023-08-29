defmodule Sandman.Http.Server do

  alias Sandman.Http.Server.ConnMatch

  alias Sandman.LuaMapper
  alias Sandman.LuerlServer

  import Sandman.Logger

  def prepare_routes(routes), do: ConnMatch.prepare_routes(routes)

  def handle_request(doc_id, luerl_server_pid, routes, {replyto_pid, request}) do
    log(doc_id, "\nHandling Incomming request ...")
    #{response, luerl_state} = case
    case ConnMatch.match(request, routes) do
    {route = %{func: func}, params} ->
      # TODO, headers and raw or parsed body here as well?
      params = params
      |> Enum.map(fn {key, val} -> {key, URI.decode(val)} end)
      |> Enum.into(%{})

      lua_args = %{
        params: params,
        query: request.query,
        headers: downcase_and_list_headers(request.headers),
        readBody: fn _ -> [ Plug.Conn.read_body(request.conn)]
        end
      }
      |> LuaMapper.reverse_map()
      log(doc_id, "Running handler for #{route.path} with #{inspect(params)}")
      # manipulates the block's state directly
      LuerlServer.call_function(luerl_server_pid, route.block_id, route.block_id, {:http_response, replyto_pid, route},
        func, [lua_args])
    nil ->
      :not_found
    end
  end

  def map_lua_response(doc_id, response) do
    response
    |> LuaMapper.map(%{
      "body" => :string,
      "status" => :integer,
      "contentType" => :string,
      "headers" => %{
        :any => fn
          s when is_bitstring(s) -> :string
          _ -> [:string]
        end
      }})
    |> case do
      {response, []} -> response
      {response, warnings} ->
        warnings = Enum.map(warnings, &LuaMapper.format/1)
        log(doc_id, ["Warnings:"] ++ warnings)
        response
    end
    |> put_defaults(doc_id)
  end

  defp put_defaults(response, doc_id) do
    response
    |> check_status(doc_id)
    |> put_default(:status, 200)
    |> put_default(:body, "")
    |> put_default(:headers, [])
  end

  defp downcase_and_list_headers(headers) when is_map(headers) do
    # erl structure
    Enum.reduce(headers, %{}, fn
      {name, val}, acc when is_bitstring(val)->
        Map.put(acc, String.downcase(name), [val])
      {name, values}, acc ->
        Map.put(acc, String.downcase(name), values)
    end)
  end

  defp check_status(response = %{status: status}, doc_id) when not status in 100..999 do
    # invalid status is server error
    log(doc_id, "Received invalid status code #{status}.")
    response
    |> Map.put(:status, 500)
    |> Map.put(:body, "Document Error")
  end
  defp check_status(response, _), do: response

  defp put_default(response, key, val) do
    case response[key] do
      nil -> Map.put(response, key, val)
      _ -> response
    end
  end
end
