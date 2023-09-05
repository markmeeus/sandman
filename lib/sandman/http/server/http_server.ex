defmodule Sandman.Http.Server do

  alias Sandman.Http.Server.ConnMatch

  alias Sandman.LuaMapper
  alias Sandman.LuerlServer

  import Sandman.Logger
  import Sandman.Http.Helpers

  def prepare_routes(routes), do: ConnMatch.prepare_routes(routes)

  def handle_request(doc_id, luerl_server_pid, routes, {replyto_pid, request}) do
    log(doc_id, "\nHandling Incomming request ... #{Enum.join(request.path_info, "/")}" )
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
        body: request.body
      }
      |> LuaMapper.reverse_map()
      log(doc_id, "Running handler for #{route.path} with #{inspect(params)}")
      # manipulates the block's state directly
      LuerlServer.spawn_function(luerl_server_pid, route.block_id, route.block_id, {:http_response, replyto_pid, route, request, route.block_id},
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

  @spec build_req_res(
          atom | %{:body => any, :conn => Plug.Conn.t(), optional(any) => any},
          atom | %{:headers => any, optional(any) => any}
        ) :: %{
          req: %{body: any, headers: any, host: any, method: any, port: any, scheme: any},
          req_content_info: %{content_type: false | nil | binary, is_json: boolean},
          res: atom | %{:headers => any, optional(any) => any},
          res_content_info: %{content_type: false | nil | binary, is_json: boolean}
        }
  def build_req_res(request, response) do
    req = %{
      scheme: request.conn.scheme,
      method: request.conn.method,
      host: request.conn.host,
      port: request.conn.port,
      path: "/" <> Enum.join(request.conn.path_info, "/"),
      query: request.conn.query_string,
      headers: request.conn.req_headers,
      body: request.body,
    }
    %{
      req: req,
      res: response,
      res_content_info: get_content_info_from_headers(response.headers),
      req_content_info: get_content_info_from_headers(req.headers),
      direction: :in
    }
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
        Map.put(acc, String.downcase(name), val)
      {name, values}, acc ->
        Map.put(acc, String.downcase(name), Enum.join(values,","))
    end)
  end

  defp check_status(response = %{status: status}, doc_id) when status not in 100..999 do
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
