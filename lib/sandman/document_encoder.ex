defmodule Sandman.DocumentEncoder do
  def encode(document) do
    ""
    |> write_title(document)
    |> write_blocks(document)
  end

  def decode(encoded) do
    %{}
    |> read_title(encoded)
    |> read_blocks(encoded)
  end

  defp write_title(encoded, %{title: title}) when is_binary(title) do
    encoded <> "#{title}\n\n"
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
    |> write_blocks( rest)
  end
  defp write_blocks(encoded, [block]) do
    write_block(encoded,block)
  end
  defp write_blocks(encoded, _) do
    encoded
  end

  defp write_block(encoded, block) do
    encoded <> "-- ::sandman::block::#{block.type}::#{block.id}\n#{block.code}\n\n"
  end

  defp read_title(document, encoded) do
    title = case String.split(encoded, "\n") do
      [title] -> title
      [title | _] -> title
    end
    Map.put(document, :title, title)
  end

  defp read_blocks(document, encoded) do
    block_header_regex = ~r/^-- ::sandman::block::(?<type>[a-z]{3})::(?<id>[0-9A-Fa-f]{8}[-]?[0-9A-Fa-f]{4}[-]?[0-9A-Fa-f]{4}[-]?[0-9A-Fa-f]{4}[-]?[0-9A-Fa-f]{12})$/

    {blocks, current_block} = Enum.reduce(String.split(encoded, "\n"), {[], nil}, fn line, {blocks, current_block} ->
      case (Regex.named_captures(block_header_regex, line)) do
        %{"id" => id, "type" => type} -> case current_block do # this is a header, is there a current block? then add to collection
          nil -> {blocks, %{type: type, id: id, code: ""}}
          current_block -> { blocks ++ [finalize_block(current_block)], %{type: type, id: id, code: ""} }
        end

        nil -> case current_block do # this is a regular line, is there a current block?
            nil -> {blocks, nil}
            block -> {blocks, Map.put(block, :code, block.code <> line <> "\n")} # add line to current code
        end
      end
    end)
    blocks = case current_block do
      nil -> blocks
      block -> blocks ++ [finalize_block(current_block)]
    end
    Map.put(document, :blocks, blocks)
  end

  defp finalize_block(block = %{code: code}) do
    Map.put(block, :code, String.trim(code))
  end
end
