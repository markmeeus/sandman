defmodule Sandman.DocumentEncoderTest do

  use ExUnit.Case
  alias Sandman.DocumentEncoder

  def new_id_fn(), do: &((&1||0) + 1)
#   test "correctly encodes a document" do
#     document = %{
#       title: "My doc title",
#       blocks: [
#         %{id: "949f07b8-3a6a-4270-a1b7-4a68582fa7af", code: "ABC\nDEF", type: "lua"},
#         %{id: "949f07b8-3a6a-4270-a1b7-4a68582fa7a3", code: "test code", type: "mkd"},
#       ]
#     }
#     assert DocumentEncoder.encode(document) == """
# # My doc title

# <!-- sandman:{"block":"949f07b8-3a6a-4270-a1b7-4a68582fa7a3"} -->

  # ```lua
# ABC
# DEF
# ```

# <!-- sandman:{"block":"949f07b8-3a6a-4270-a1b7-4a68582fa7a4"} -->

# ```lua
# test code
# """
#   end

  test "writes empty document" do
    document = %{}
    assert DocumentEncoder.encode(document) == ""
  end

  test "reads empty document" do
    encoded = ""
    assert DocumentEncoder.decode(encoded, new_id_fn()) == %{blocks: []}
  end



  test "writes a block" do
    document = %{blocks: [%{id: "867b6036-67a6-4afd-9857-050f21e24618", code: "ola pola", type: "lua"}]}
    assert DocumentEncoder.encode(document) == """
```lua
ola pola
```
"""
  end
  test "writes multiple blocks" do
    document = %{blocks: [
      %{id: "867b6036-67a6-4afd-9857-050f21e24618", code: "ola pola", type: "lua"},
      %{id: "867b6036-67a6-4afd-9857-050f21e24619", code: "ola\npola", type: "lua"}
    ]}
    assert DocumentEncoder.encode(document) == """
```lua
ola pola
```

```lua
ola
pola
```
"""
  end

  test "writes multiple blocks with markdown" do
    document = %{blocks: [
      %{id: "867b6036-67a6-4afd-9857-050f21e24618", code: "lua code block 1", type: "lua"},
      %{id: "867b6036-67a6-4afd-9857-050f21e24620", code: "markdown", type: "markdown"},
      %{id: "867b6036-67a6-4afd-9857-050f21e24619", code: "lua code block 2", type: "lua"},
    ]}
    assert DocumentEncoder.encode(document) == """
```lua
lua code block 1
```

markdown

```lua
lua code block 2
```
"""
  end

  test "reads multiple blocks" do
    encoded = """
```lua
ola pola1
```
```lua
ola
pola
2
```
"""
    document = %{blocks: [
      %{id: 1, code: "ola pola1", type: "lua", state: :empty},
      %{id: 2, code: "ola\npola\n2", type: "lua", state: :empty}
    ]}

    assert DocumentEncoder.decode(encoded, new_id_fn()) == document
  end


  test "reads a single markdown block" do
    encoded = "#title\nola pola"
    document = %{blocks: [
      %{id: 1, code: "#title\nola pola", type: "markdown", state: :empty},
    ]}

    assert DocumentEncoder.decode(encoded, new_id_fn()) == document
  end

  test "keeps newlines in text" do
    encoded = """
```lua
ola

pola1
```
"""
    document = %{blocks: [
      %{id: 1, code: "ola\n\npola1", type: "lua", state: :empty},
    ]}

    assert DocumentEncoder.decode(encoded, new_id_fn()) == document
  end

  test "reads combination of markdown and lua blocks" do
    encoded = """
#title
ola pola

```lua
ola
pola
```
"""
    document = %{blocks: [
      %{id: 1, code: "#title\nola pola", type: "markdown", state: :empty},
      %{id: 2, code: "ola\npola", type: "lua", state: :empty},
    ]}
    assert DocumentEncoder.decode(encoded, new_id_fn()) == document
  end

  test "reads combinations of markdown and lua blocks" do
    encoded = """
#title
ola pola

```lua
ola
pola
```
#title2
ola pola
2

```lua
ola
pola
2
```
"""
    document = %{blocks: [
      %{id: 1, code: "#title\nola pola", type: "markdown", state: :empty},
      %{id: 2, code: "ola\npola", type: "lua", state: :empty},
      %{id: 3, code: "#title2\nola pola\n2", type: "markdown", state: :empty},
      %{id: 4, code: "ola\npola\n2", type: "lua", state: :empty},
    ]}
    assert DocumentEncoder.decode(encoded, new_id_fn()) == document
  end
end
