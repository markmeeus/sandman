defmodule Sandman.LuaMappperTest do
  use ExUnit.Case

  import Sandman.LuaMapper

  test "it maps a simple table" do
    lua_table = [{"att1", "ola"}, {"att2", 4.5}]
    schema = %{
      "att1" => :string,
      "att2" => :number
    }
    assert map(lua_table, schema) == {%{ att1: "ola", att2: 4.5}, []}
  end

  test "it maps any attributes" do
    lua_table = [{"att1", "ola"}, {"att2", "4.5"}]
    schema = %{
      :any => :string
    }
    assert map(lua_table, schema) == {%{ "att1" => "ola", "att2" => "4.5"}, []}
  end
  test "it does not convert attribute names when using :any" do
    lua_table = [{"MY_Att_a", "ola"}, {"att2", "4.5"}]
    schema = %{
      :any => :string
    }
    assert map(lua_table, schema) == {%{ "MY_Att_a" => "ola", "att2" => "4.5"}, []}
  end

  test "it maps any values" do
    lua_table = [{"att1", "ola"}, {"att2", "4.5"}, {"att3", [{1, 3},{2, true}]}]
    schema = :any
    assert map(lua_table, schema) == {%{"att1" => "ola", "att2" => "4.5", "att3" => [3, true]}, []}
  end

  test "it does not crash on unexptected chid" do
    lua_table = [{"a",2},{"b", 2.0}, {"c", "d"}, {"test", [{1, "a"}, {2, "b"}]}]
    schema = %{
      :any => [:string]
    }
    assert map(lua_table, schema) == {
      %{"a" => "", "b" => "", "c" => "", "test" => ["a", "b"]},
      [{["a"], :unexpected_type, :integer, :table, "2"},
      {["b"], :unexpected_type, :float, :table, "2.0"},
      {["c"], :unexpected_type, :string, :table, "\"d\""}]
    }
  end

  test "it maps camelcase to underscore" do
    lua_table = [{"someKey", "value"}]
    schema = %{
      "someKey" => :string
    }
    assert map(lua_table, schema) == {%{ some_key: "value"}, []}
  end

  test "it returns warnings for attributes that were not mapped" do
    lua_table = [{"att1", "ola"}, {"att3", 4.5}]
    schema = %{
      "att1" => :string,
      "att2" => :number
    }
    assert map(lua_table, schema) == {%{ att1: "ola"}, [{[], "att3", :unknown_attribute}]}
  end

  test "it returns warnings with path info for attributes that were not mapped" do
    lua_table = [{"att1", [{"att3", 4.5}]}]
    schema = %{
      "att1" => %{
        "att2" => %{
        }
      },

    }
    assert map(lua_table, schema) == {%{ att1: %{}}, [{["att1"], "att3", :unknown_attribute}]}
  end

  test "it truncates integer values" do
    lua_table = [{"att2", 4.5}]
    schema = %{
      "att2" => :integer
    }
    assert map(lua_table, schema) == {%{ att2: 4}, []}
  end

  test "it converts floats to string" do
    lua_table = [{"att2", 4.5}]
    schema = %{
      "att2" => :string
    }
    assert map(lua_table, schema) == {%{ att2: "4.5"}, []}
  end

  test "it converts integers to string" do
    lua_table = [{"att2", 4}]
    schema = %{
      "att2" => :string
    }
    assert map(lua_table, schema) == {%{ att2: "4"}, []}
  end

  test "it maps sub tables" do
    lua_table = [{"child", [{"first", "john"}]}]
    schema = %{
      "child" => %{
        "first" => :string
      }
    }
    assert map(lua_table, schema) == { %{ child: %{ first: "john"}}, []}
  end

  test "it maps a table to a list" do
    lua_table = [{1, "a"}, {2, "b"}]
    schema = [:string]
    assert map(lua_table, schema) == { ["a", "b"], []}
  end

  test "it maps a table to a tuple" do
    lua_table = [{1, "a"}, {2, "b"}]
    schema = {:string, :string}
    assert map(lua_table, schema) == { {"a", "b"}, []}
  end

  test "it adds a warning when tuple is incomplete" do
    lua_table = [{1, "a"}, {2, "b"}]
    schema = {:string, :string, :integer}
    assert map(lua_table, schema) == { {"a", "b"}, [[], "", :tuple_incomplete]}
  end

  test "it adds a warning when tuple has too much data" do
    lua_table = [{1, "a"}, {2, 12.4}, {3, "c"}]
    schema = {:string, :numeric}
    assert map(lua_table, schema) == { {"a", 12.4}, [[], "", :tuple_overloaded]}
  end

  test "it maps a badly sorted table to a list (list of tuples)" do
    lua_table = [{2, "a"}, {1, "b"}]
    schema = [:string]
    assert map(lua_table, schema) == { ["b", "a"], []}
  end

  test "this" do
    schema = %{
      "text" => :string,
      "highlighted" => :string,
      "opacity" => :boolean,
      "position" => {:number, :number},
      "size" => {:number, :number}
      }
    args = [{"position", [{1, 4.0}, {2, 4.0}]}, {"text", "ola"}]
    assert map(args, schema) == {%{position: {4, 4}, text: "ola"}, []}
  end
  test "it maps more complex stuff" do
    lua_table = [
      {"color", "green"},
      {"positions", [
        {1, [{"lat", 12}, {"lng", 15}]},
        {2, [{"lat", 22}, {"ln", 25}]},
      ]}
    ]
    schema = %{
      "color" => :string,
      "positions" => [
        %{
          "lat" => :integer,
          "lng" => :integer
        }
      ]}
    expected = %{
      color: "green",
      positions: [
        %{lat: 12, lng: 15},
        %{lat: 22}
      ]
    }

    assert map(lua_table, schema) == {expected, [{["positions"], "ln", :unknown_attribute}]}
  end
  test "supports custom schema matching" do
    schema =
      %{
        "position" => fn
          [{_, _},{_, _}] ->
            {:integer, :integer}
          [{_, _},{_, _},{_, _},{_, _},{_, _}] ->
            {:string, :string, :string, :integer, :integer}
        end
      }
    lua_table = [
        {"position", [{1, "ref"}, {2, "_1"}, {3, "bottom-3"}, {4, 3.4}, {5, 4.4}]},
      ]
    assert map(lua_table, schema) == {%{position: {"ref", "_1", "bottom-3", 3, 4}}, []}
  end

  test 'it should map this:' do
    lua_table = [
      {"points",
      [
        {1, [{1, 1}, {2, 1}]},
        {2, [{1, "ref"}, {2, 1}, {3, "left-4"}, {4, 0}, {5, 0}]},
      ]},
      {"route", true}
    ]
    schema = %{
        "points" => [
          fn
            [{_, _}, {_, _}] ->
              {:integer, :integer}

            [{_, _}, {_, _}, {_, _}, {_, _}, {_, _}] ->
              {:string, :integer, :string, :integer, :integer}
          end
        ],
        "arrows" => {:string, :string},
        "highlighted" => :boolean,
        "visible" => :boolean,
        "route" => :boolean
      }
    map(lua_table, schema) #.route == true
  end

  test "should not crash when string is unexpected" do
    schema = %{
      "val" => :string
    }
    lua_table = "test"
    {result, warnings} = map(lua_table, schema)
    assert result == %{}
    assert warnings == [{[], :unexpected_type, :table, :any, "\"test\""}]
  end

  test "should not crash when string is unexpected in field" do
    schema = %{
      "val" => %{
        value: :string
      }
    }
    lua_table = [{"val", "test"}]
    {result, warnings} = map(lua_table, schema)
    assert result == %{val: %{}}
    assert warnings == [{["val"], :unexpected_type, :table, :any, "\"test\""}]
  end

  test "should not crash when received table instead of string" do
    schema = %{
      "val" => :string
    }
    lua_table = [{"val", [{"test", "true"}]}]
    {result, warnings} = map(lua_table, schema)
    assert result == %{val: ""}
    assert warnings == [{["val"], :unexpected_type, :string, :table, "{test=\"true\"}"}]
  end

  test "should not crash when received table instead of :integer" do
    schema = %{
      "val" => :integer
    }
    lua_table = [{"val", [{"test", "true"}]}]
    {result, warnings} = map(lua_table, schema)
    assert result == %{val: ""}
    assert warnings == [{["val"], :unexpected_type, :integer, :table, "{test=\"true\"}"}]
  end

  test "it should convert strings to integer with warning" do
    schema = %{
      "val" => :integer
    }
    lua_table = [{"val", "200"}]
    {result, warnings} = map(lua_table, schema)
    assert result == %{val: 200}
    assert warnings == [{["val"], :unexpected_type, :integer, :string, "\"200\""}]
  end

  test "it should convert strings to integer 0 with warning" do
    schema = %{
      "val" => :integer
    }
    lua_table = [{"val", "unparseable 200"}]
    {result, warnings} = map(lua_table, schema)
    assert result == %{val: 0}
    assert warnings == [{["val"], :unexpected_type, :integer, :string, "\"unparseable 200\""}]
  end

  test "it should format unexpected type warnings" do
    formatted = format(
      {["path", "to"], :unexpected_type, :integer, :string, "'200'"})
    assert formatted == "path.to expected to be of type integer, received string: '200'"
  end
  test "it should format unexpected type warnings with any type" do
    formatted = format(
      {["path", "to"], :unexpected_type, :table, :any, "'200'"})
    assert formatted == "path.to expected to be of type table, received : '200'"
  end

  test "it should format unknown_attribute warnings" do
  formatted = format(
      {["path", "to"], "att3", :unknown_attribute})
    assert formatted == "path.to expected no attribute named 'att3'"

  end
end
