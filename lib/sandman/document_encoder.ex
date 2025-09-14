defmodule Sandman.DocumentEncoder do
  def encode(document) do
    ""
    |> write_blocks(document)
  end

  def decode(encoded, new_id_fn) do
    %{}
    |> read_blocks(encoded, new_id_fn)
  end


  defp write_blocks(encoded, %{blocks: blocks}) do
    write_blocks(encoded, blocks)
  end
  defp write_blocks(encoded, [block | rest]) do
    encoded
    |> write_block(block, encoded == "")
    |> write_blocks(rest)
  end
  defp write_blocks(encoded, _) do
    encoded
  end

  defp write_block(encoded, block, true) do
    encoded <> serialize_block(block)
  end
  defp write_block(encoded, block, false) do
    encoded <> "\n" <> serialize_block(block)
  end

  defp serialize_block(%{type: "lua", code: code}), do: "```lua\n#{code}\n```\n"
  # markdown blocks are just markdown
  defp serialize_block(block), do: block.code <> "\n"


  defp read_blocks(document, encoded, new_id_fn) do
    {blocks, last_block, _last_id} = Enum.reduce(String.split(encoded, "\n"), {[], nil, nil}, fn line, {blocks, current_block, last_id} ->
      case read_block_header(line) do
        :lua ->
          case current_block do
            # this is a lua header, if there no current block? then create one
            nil ->
              new_id = new_id_fn.(last_id)
              {blocks, %{type: "lua", id: new_id, code: "", state: :empty}, new_id}
            %{type: "lua"} ->
              # there is a current lua block, let's treat this a normal line
              # terminating lua blocks is handled by the add_line_to_current_block function
              add_line_to_current_block({blocks, current_block}, line)
            _block ->
              # no current lua block, lets add this one and create a new one
              new_id = new_id_fn.(last_id)
              {blocks ++ [current_block], %{type: "lua", id: new_id, code: "", state: :empty}, new_id}
          end

        # not a header line, this is either markdown or lua code
        # depending on the type of the current block
        # but that does not matter, we should just add the line
        nil ->
          case current_block do
            nil ->
              new_id = new_id_fn.(last_id)
              {blocks, %{type: "markdown", id: new_id, code: line, state: :empty}, new_id}
            _block ->
              {blocks, current_block} = add_line_to_current_block({blocks, current_block}, line)
              {blocks, current_block, last_id}
        end
      end
    end)

    blocks = case last_block do
      nil -> blocks
      _block -> blocks ++ [last_block]
    end
    |> Enum.map(fn
      block =%{type: "markdown", code: code} ->
        block = if String.ends_with?(code, "\n") do
          %{block | code: String.slice(code, 0..-2//1)}
        else
          block
        end
      block -> block
    end)
    |> Enum.filter(fn block -> block.code != "" end)
    Map.put(document, :blocks, blocks)
  end

  defp read_block_header(line) do
    block_header_regex = ~r/```(?<lang>.*)$/
    case (Regex.named_captures(block_header_regex, line)) do
      %{"lang" => "lua"} -> :lua
      _ -> nil
    end
  end

  #defp add_line_to_current_block({blocks, cb = %{code: ""}}, "```lua"), do: {blocks, cb}
  defp add_line_to_current_block({blocks, cb}, "```"), do: {blocks ++ [cb], nil} #end of block
  defp add_line_to_current_block({blocks, cb = %{code: ""}}, line) do
    {blocks, Map.put(cb, :code, line)}
  end
  defp add_line_to_current_block({blocks, cb}, line) do
    {blocks, Map.put(cb, :code, cb.code <> "\n" <> line)} #end of block
  end
end
