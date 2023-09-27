defmodule SandmanWeb.RequestController do
  use SandmanWeb, :controller
  alias Sandman.Document

  def req(conn, params) do
    respond_with_body(conn, params, :request)
  end

  def res(conn, params) do
    respond_with_body(conn, params, :response)
  end

  defp respond_with_body(conn, params = %{"doc_pid" => doc_pid,
    "block_id" => block_id, "id" => request_id}, type) do

      doc_pid = doc_pid
    |> Base.url_decode64!()
    |> :erlang.binary_to_term()

    request_id = String.to_integer(request_id)

    req = Document.get_request_by_id(doc_pid, {block_id, request_id})
    {content_info, body} = get_request_info(req, type)
    if (params["raw"]) do
      conn
      |> put_layout(false)
      |> put_root_layout(false)
      |> render("raw_body.html", body: body)
    else
      respond_for_content_info(conn, body, content_info)
    end
  end

  defp get_request_info(req_res, :request)  do
    {req_res.req_content_info, req_res.req.body}
  end
  defp get_request_info(req_res, :response) do
    {req_res.res_content_info, req_res.res.body}
  end

  defp respond_for_content_info(conn, body, content_info) do
    content_type = content_info.content_type || "text/html" # default to text/html

    conn = if content_info.is_json do
        put_resp_header(conn, "content-type", "text/html")
    else
        put_resp_header(conn, "content-type", content_type)
    end
    respond_for_content_type(conn, String.downcase(content_type), body || "")
  end

  defp respond_for_content_type(conn, "application/json" <> _, body) do
    conn
    |> put_layout(false)
    |> put_root_layout(false)
    |> render("json.html", json: body)
  end

  # this is the default 'preview' response, raw as it was sent -> to iframe
  defp respond_for_content_type(conn, _content_type, body) do
    resp(conn, 200, body)
  end
end
