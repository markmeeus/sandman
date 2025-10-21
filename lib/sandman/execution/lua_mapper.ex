defmodule Sandman.LuaMapper do
  def map(lua_table, schema, path \\ [])
  # mapping a table into a map
  def map(lua_value, :any, _path) do
    {map_unchecked(lua_value), []}
  end
  def map(lua_value, schema_fn, path) when is_function(schema_fn) do
    schema = schema_fn.(lua_value)
    map(lua_value, schema, path)
  end

  def map(lua_term, schema, path) when is_map(schema) and not is_list(lua_term) do
    {%{}, [{path, :unexpected_type, :table, :any, to_lua_code(lua_term)}]}
  end

  def map(lua_table, %{:any => child_schema}, path) do
    Enum.reduce(lua_table, {%{}, []}, fn {key, val}, {map, warnings} ->
      {val, child_warnings} = map(val, child_schema, path ++ [key])
      map_key = to_string(key) # unname items in a table get numbers as key
      {Map.put(map, map_key, val), warnings ++ child_warnings}
    end)
  end

  def map(lua_table, schema, path) when is_map(schema) do
    Enum.reduce(lua_table, {%{}, []}, fn {key, val}, {map, warnings} ->
      case schema[key] do
        nil ->
          {map, warnings ++ [{path, key, :unknown_attribute}]}

        val_schema ->
          {val, child_warnings} = map(val, val_schema, path ++ [key])

          map_key =
            key
            |> Macro.underscore()
            |> String.to_atom()

          {Map.put(map, map_key, val), warnings ++ child_warnings}
      end
    end)
  end

  # mapping a lua table into a list
  def map(lua_table, schema = [member_schema], path) when is_list(schema) and is_list(lua_table) do
    lua_table
    # some sorting here?
    |> Enum.sort(fn {i1, _}, {i2, _} -> i1 < i2 end)
    |> Enum.reduce({[], []}, fn {_index, val}, {list, warnings} ->
      {mapped_val, child_warnings} = map(val, member_schema, path)
      {list ++ [mapped_val], warnings ++ child_warnings}
    end)
  end
  def map(val, schema = [_member_schema], path) when is_list(schema) and is_integer(val) do
    {"", [{path, :unexpected_type, :table, :integer, to_lua_code(val)}]}
  end
  def map(val, schema = [_member_schema], path) when is_list(schema) and is_float(val) do
    {"", [{path, :unexpected_type, :table, :integer, to_lua_code(val)}]}
  end
  def map(val, schema = [_member_schema], path) when is_list(schema) and is_bitstring(val) do
    {"", [{path, :unexpected_type, :table, :string, to_lua_code(val)}]}
  end
  def map(val, schema = [_member_schema], path) when is_list(schema) and is_boolean(val) do
    {"", [{path, :unexpected_type, :table, :boolean, to_lua_code(val)}]}
  end

  def map(lua_table, schema, path) when is_tuple(schema) do
    # first map the table to a list
    {list, _} = map(lua_table, [:any], path)
    # combine list and schemas
    schema_list = Tuple.to_list(schema)

    schema_count = Enum.count(schema_list)
    table_count = Enum.count(lua_table)

    warnings =
      if schema_count == table_count do
        []
      else
        if schema_count > table_count,
          do: [path, "", :tuple_incomplete],
          else: [path, "", :tuple_overloaded]
      end

    {result, warnings} =
      schema_list
      |> Enum.zip(list)
      |> Enum.reduce({[], warnings}, fn {member_schema, value}, {result, warnings} ->
        {member_val, member_warnings} = map(value, member_schema, path)
        {result ++ [member_val], warnings ++ member_warnings}
      end)

    {List.to_tuple(result), warnings}
  end

  def map(val, :integer, path) when is_list(val) do
    {"", [{path, :unexpected_type, :integer, :table, to_lua_code(val)}]}
  end
  def map(val, :integer, path) when is_bitstring(val) do
    integer = case Integer.parse(val) do
      :error -> 0
      {integer, _} -> integer
    end
    {integer, [{path, :unexpected_type, :integer, :string, to_lua_code(val)}]}
  end
  def map(val, :integer, _path) when is_number(val) do
    {trunc(val), []}
  end

  def map(val, :string, path) when is_integer(val), do: map(to_string(val), :string, path)
  def map(val, :string, path) when is_float(val), do: map(to_string(val), :string, path)
  def map(val, :string, path) when is_list(val) do
    {"", [{path, :unexpected_type, :string, :table, to_lua_code(val)}]}
  end

  def map(val, schema, _path) when is_atom(schema) do
    {val, []}
  end

  def map_unchecked(lua_table) when is_list(lua_table) do
    if Enum.any?(lua_table, &!is_integer(elem(&1,0))) do
      # at least one key is a non-integer, so it's a map
      # map every item unchecked and insert into an map
      Enum.reduce(lua_table, %{}, fn
        {k, v}, map -> Map.put(map, k, map_unchecked(v))
      end)
    else
      # only integer keys is a list
      # map every item unchecked and return a list
      Enum.map(lua_table, fn {_, v} -> map_unchecked(v) end)
    end

  end
  def map_unchecked(lua_val), do: lua_val

  def reverse_map(termex) when is_map(termex) do
      Enum.map(termex, fn {key, val} ->
        {key, reverse_map(val)}
      end)
  end
  def reverse_map(termex) when is_list(termex) do
    # TODO, mapping lists is as simple as adding integers in the tuples
    {result, _} = Enum.reduce(termex, {[], 1}, fn item, {result, index} ->
      result = result ++ [{index, reverse_map(item)}]
      {result, index + 1}
    end)
    result
  end
  def reverse_map(termex), do: termex

  def to_lua_code(termex) when is_bitstring(termex), do: "\"#{termex}\""
  def to_lua_code(termex) when is_number(termex), do: "#{termex}"
  def to_lua_code(true), do: "true"
  def to_lua_code(false), do: "false"
  def to_lua_code(nil), do: "nil"
  # encoded tables are in list form
  def to_lua_code(termex) when is_list(termex) do
    ("{" <>
       (Enum.map(termex, fn
          {key, val} ->
            "#{key}=#{to_lua_code(val)}"
        end)
        |> Enum.join(", ")) <>
       "}")
  end

  def to_lua_code(termex) when is_function(termex), do: "function"
  def to_lua_code(_termex), do: "?" # dont leak any internals please

  def to_printable(termex, root\\true)
  def to_printable(termex, true) when is_bitstring(termex) do
    if String.valid?(termex) do
      trim(termex)
    else
      "<binary: #{Base.encode64(termex) |> trim()}>"
    end
  end

  def to_printable(termex, false) when is_bitstring(termex) do
    if String.valid?(termex) do
      "\"#{trim(termex)}\""
    else
      "<binary: #{Base.encode64(termex) |> trim()}>"
    end
  end
  def to_printable(termex, _) when is_number(termex), do: termex
  def to_printable(true, _), do: "true"
  def to_printable(false, _), do: "false"
  def to_printable(nil, _), do: "nil"
  # encoded tables are in list form
  def to_printable(termex, _) when is_list(termex) do
    ("{" <>
       (Enum.map(termex, fn
          {key, val} ->
            "#{trim(to_string(key))}=#{to_printable(val, false)}"
        end)
        |> Enum.join(", ")
        |> trim()
        ) <>
       "}")
  end
  def to_printable(termex, _) when is_function(termex), do: "function"
  def to_printable(_termex, _), do: "?" # dont leak any internals please

  def trim(printable) do
    if(String.length(printable) > 1024) do
      {lead, rest} = String.split_at(printable, 1000)
      {_middle, trail} = String.split_at(rest, -10)
      lead <> "..." <> trail
    else
      printable
    end
  end

  def format(warnings) when is_list(warnings) do
    warnings
    |> Enum.map(&format/1)
    |> Enum.join("\n")
  end
  def format({path, :unexpected_type, expected_type, received_type, value}) do
    "#{Enum.join(path, ".")} expected to be of type #{expected_type}, received #{format_type(received_type)}: #{value}"
  end
  def format({path, att_name, :unknown_attribute}) do
    "#{Enum.join(path, ".")} expected no attribute named '#{att_name}'"
  end

  defp format_type(:any), do: ""
  defp format_type(type_name), do: to_string(type_name)
end
