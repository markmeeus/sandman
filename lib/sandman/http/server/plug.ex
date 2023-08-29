defmodule Sandman.UserPlug do
  import Plug.Conn

  def init({document_pid, server_id}) do
    # initialize options
    %{document_pid: document_pid, server_id: server_id}
  end
  def call(conn, args) do
    conn = Plug.Conn.fetch_query_params(conn)
    request = to_request(conn)
    response = Sandman.Document.handle_server_request(args.document_pid, args.server_id, request)
    conn = Enum.reduce(response[:headers] || %{}, conn, fn
        {name, value}, conn when is_bitstring(value) ->
          %{conn | resp_headers: [{name, value}] ++ conn.resp_headers}
        {name, values}, conn when is_list(values) ->
          Enum.reduce(values, conn, fn value, conn ->
            %{conn | resp_headers: [{name, value}] ++ conn.resp_headers}
          end )
      end)
    conn = send_resp(conn, response.status, response.body)
    halt(conn)
  end

  def to_request(conn) do
    # create a request, wrap it in a gen_server, and pass the pid
    %{
      conn: conn,
      method: conn.method,
      path_info: conn.path_info,
      query: conn.query_params,
      headers: Enum.into(conn.req_headers, %{})
    }
  end
end
