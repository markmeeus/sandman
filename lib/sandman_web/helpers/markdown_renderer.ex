defmodule Sandman.MarkdownRenderer do
  def render_with_target_blank(markdown) do
    with {:ok, ast, _} <- Earmark.as_ast(markdown) do
      ast
      |> add_target_blank()
      |> Earmark.Transform.transform()
      |> Phoenix.HTML.raw()
    end
  end

  defp add_target_blank(ast) do
    Enum.map(ast, &process_node/1)
  end

  defp process_node({"a", attrs, children, meta}) do
    # Add target="_blank" unless already set
    attrs = [
      {"target", "_blank"},
      {"onclick", "event.stopPropagation()"}
    | attrs]

    {"a", attrs, add_target_blank(children), meta}
  end

  defp process_node({tag, attrs, children, meta}) do
    {tag, attrs, add_target_blank(children), meta}
  end

  defp process_node(text) when is_binary(text), do: text
end
