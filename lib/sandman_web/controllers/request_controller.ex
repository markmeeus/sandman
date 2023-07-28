defmodule SandmanWeb.RequestController do
  use SandmanWeb, :controller
  alias Sandman.Document

  def show(conn, params = %{"doc_pid" => doc_pid, "block_id" => block_id, "id" => request_id}) do
    # The home page is often custom made,
    # so skip the default app layout.
    doc_pid = doc_pid
    |> Base.url_decode64!()
    |> :erlang.binary_to_term()

    request_id = String.to_integer(request_id)

    req = Document.get_request_by_id(doc_pid, {block_id, request_id})
    content_type = req.res_content_type || "application/text"

    if req.res_is_json do
        put_resp_header(conn, "content-type", "text/html")
    else
        put_resp_header(conn, "content-type", content_type)
    end

    |> respond_for_content_type(String.downcase(content_type), req)
  end

  defp respond_for_content_type(conn, "application/json", req) do
    conn
    |> put_layout(false)
    |> put_root_layout(false)
    |> render("json.html", json: req.res.body)
  end
  defp respond_for_content_type(conn, content_type, req) do
    resp(conn, 200, req.res.body)
  end
end
