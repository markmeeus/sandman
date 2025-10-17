defmodule Sandman.RequestFormatting do

  def format_request(%{req: nil}), do: "" # this happens with invalid requests. The error should say enough

  def format_request(%{req: req, direction: direction, call_info: call_info}) do
    "#{in_or_out(direction)} #{String.upcase(to_string(req.method))} #{req.scheme}://#{req.host}"
    |> add_port(req.scheme, req.port)
    |> add_path(req.path)
    |> add_query(req.query)
    |> add_call_info(call_info)
  end

  def format_url(%{req: req}) do
    "#{req.scheme}://#{req.host}"
    |> add_port(req.scheme, req.port)
    |> add_path(req.path)
    |> add_query(req.query)
  end

  # for no info on direction
  def in_or_out(:in), do: "↘"
  def in_or_out(:out), do: "↗"

  defp add_port(formatted, :http, 80), do: formatted
  defp add_port(formatted, :https, 443), do: formatted
  defp add_port(formatted, _, port), do: "#{formatted}:#{port}"

  defp add_path(formatted, path), do: "#{formatted}#{path}"

  defp add_query(formatted, nil), do: formatted
  defp add_query(formatted, q), do: "#{formatted}?#{q}"

  defp add_call_info(formatted, nil), do: formatted

  defp add_call_info(formatted, %{line_nr: line_nr}), do: "#{formatted} @:#{line_nr}"
end
