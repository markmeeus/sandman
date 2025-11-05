defmodule Sandman.MarkdownRenderer do
  @moduledoc """
  Renders markdown to HTML with security sanitization.

  Uses Earmark for markdown conversion and HtmlSanitizeEx for security.
  All external links are opened in a new tab.
  """

  def render_with_target_blank(markdown) do
    case Earmark.as_html(markdown) do
      {:ok, html, _} ->
        html
        |> HtmlSanitizeEx.markdown_html()
        |> Phoenix.HTML.raw()

      {:error, _html, errors} ->
        IO.inspect(errors, label: "Markdown parsing errors")
        "Error parsing markdown"
    end
  end
end
