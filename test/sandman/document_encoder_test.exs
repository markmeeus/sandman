defmodule Sandman.DocumentEncoderTest do

  use ExUnit.Case
  alias Sandman.DocumentEncoder

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
    assert DocumentEncoder.decode(encoded) == %{title: "", blocks: []}
  end

  test "write title" do
    document = %{title: "this is a title"}
    assert DocumentEncoder.encode(document) == """
this is a title
"""
  end

  test "reads title" do
    encoded = """
this is a title
"""
    assert DocumentEncoder.decode(encoded) == %{title: "this is a title", blocks: []}
  end

  test "writes a block" do
    document = %{title: "this is a title", blocks: [%{id: "867b6036-67a6-4afd-9857-050f21e24618", code: "ola pola", type: "lua"}]}
    assert DocumentEncoder.encode(document) == """
this is a title

<!-- sandman:{"block":"867b6036-67a6-4afd-9857-050f21e24618"} -->

```lua
ola pola
```
"""
  end
  test "writes multiple blocks" do
    document = %{title: "this is a title", blocks: [
      %{id: "867b6036-67a6-4afd-9857-050f21e24618", code: "ola pola"},
      %{id: "867b6036-67a6-4afd-9857-050f21e24619", code: "ola\npola"}
    ]}
    assert DocumentEncoder.encode(document) == """
this is a title

<!-- sandman:{"block":"867b6036-67a6-4afd-9857-050f21e24618"} -->

```lua
ola pola
```

<!-- sandman:{"block":"867b6036-67a6-4afd-9857-050f21e24619"} -->

```lua
ola
pola
```
"""
  end

  test "reads multiple blocks" do
    encoded = """
this is a title

<!-- sandman:{"block":"867b6036-67a6-4afd-9857-050f21e24618"} -->

```lua
ola pola1
```

<!-- sandman:{"block":"867b6036-67a6-4afd-9857-050f21e24619"} -->

```lua
ola
pola
2
```
"""
    document = %{title: "this is a title", blocks: [
      %{id: "867b6036-67a6-4afd-9857-050f21e24618", code: "ola pola1", type: "lua"},
      %{id: "867b6036-67a6-4afd-9857-050f21e24619", code: "ola\npola\n2", type: "lua"}
    ]}

    assert DocumentEncoder.decode(encoded) == document
  end
end
