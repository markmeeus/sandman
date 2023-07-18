defmodule Sandman.DocumentEncoder do
  def encode(document) do
    ""
    |> write_title(document)
    |> write_blocks(document)
  end

  def decode(encoded, new_id_fn) do
    %{}
    |> read_title(encoded)
    |> read_blocks(encoded, new_id_fn)
  end

  defp write_title(encoded, %{title: title}) when is_binary(title) do
    encoded <> "#{title}\n"
  end
  defp write_title(encoded, _) do
    encoded
  end

  defp write_blocks(encoded, %{blocks: blocks}) do
    write_blocks(encoded, blocks)
  end
  defp write_blocks(encoded, [block | rest]) do
    encoded
    |> write_block(block)
    |> write_blocks(rest)
  end
  defp write_blocks(encoded, [block]) do
    write_block(encoded,block)
  end
  defp write_blocks(encoded, _) do
    encoded
  end

  defp write_block(encoded, block) do
    encoded <> "\n```lua\n#{block.code}\n```\n"
  end

  defp read_title(document, encoded) do
    title = case String.split(encoded, "\n") do
      [title] -> title
      [title | _] -> title
    end
    Map.put(document, :title, title)
  end

  defp read_blocks(document, encoded, new_id_fn) do
    {blocks, current_block} = Enum.reduce(String.split(encoded, "\n"), {[], nil}, fn line, {blocks, current_block} ->

      case read_block_header(line) do
        :lua -> case current_block do
          # this is a header, is there no current block? then create one
          nil -> {blocks, %{type: "lua", id: new_id_fn.(Enum.count(blocks)), code: ""}}
          current_block ->
            # there is a current block, let's treat this a normal line
            add_line_to_current_block({blocks, current_block}, line)
        end

        nil -> case current_block do # not a header line
            nil -> {blocks, nil} # this wil later add to md current block
            block ->
              add_line_to_current_block({blocks, current_block}, line)
        end
      end
    end)

    Map.put(document, :blocks, blocks)
  end

  defp read_block_header(line) do
    block_header_regex = ~r/^<!-- sandman:(?<json>.*)-->$/
    block_header_regex = ~r/```(?<lang>.*)$/
    case (Regex.named_captures(block_header_regex, line)) do
      %{"lang" => "lua"} -> :lua
      _ -> nil
    end
  end

  #defp add_line_to_current_block({blocks, cb = %{code: ""}}, "```lua"), do: {blocks, cb}
  defp add_line_to_current_block({blocks, cb}, "```"), do: {blocks ++ [cb], nil} #end of block
  defp add_line_to_current_block({blocks, cb}, line) do
    {blocks, Map.put(cb, :code, String.trim(cb.code <> "\n" <> line))} #end of block
  end
end
