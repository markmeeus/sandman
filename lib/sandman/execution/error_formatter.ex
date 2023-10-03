defmodule Sandman.ErrorFormatter do

  def format_parse_error([{line_nr, :luerl_comp_lint, :illegal_varargs}]) do
    "Invalid Code at #{line_nr}: cannot use '...' outside a vararg function"
  end
  def format_parse_error([{line_nr, :luerl_comp_lint, :assign_mismatch}]) do
    "Invalid Code at #{line_nr}: assign mismatch variables and expressions"
  end
  def format_parse_error([{line_nr, :luerl_parse, info}]) when is_list(info) do
    # list in this case is codepoint list, if this code is called with a list of lists .... refactor don't just Enum.join
    "Invalid Code at #{line_nr}: #{info}"
  end
  def format_parse_error([{line_nr, :luerl_scan, {:illegal, illegal}}]) do
    # illegal can be an entire script
    illegal =  to_string(illegal)
    |> String.slice(0, 10)
    |> String.replace("\n", "\\n")
    "Illegal at #{line_nr}: => #{illegal}"
  end
  def format_parse_error([{line_nr, :luerl_scan, {:user, illegal}}]) do
    # illegal can be an entire script
    illegal =  to_string(illegal)
    |> String.slice(0, 100)
    |> String.replace("\n", "\\n")
    "Illegal at #{line_nr}: => #{illegal}"
  end

  def format_parse_error(error) do
   "Parse Error:" <> inspect(error)
  end

  def format_lua_error(error, luerl_state) do
    IO.inspect(luerl_state)
    stack = :luerl.get_stacktrace(luerl_state)
    IO.inspect(stack)
    format_error_and_stack(error, stack, luerl_state)
  end

  def format_exception(%ErlangError{original: {:recursive_table, _}}, luerl_state) do
    stack = :luerl.get_stacktrace(luerl_state)
    #TODO: misschien proberen om de variable name uit de luerl_state te halen?
    # En waarom werkt de stack trace hier niet? is precies []
    # Waarom zit dat in eezn ErlangError

    "Error:" <> "Recursive Table" <>
    "\n" <> format_stack(stack, luerl_state) <> "\n"
  end
  def format_exception(exception, _luerl_state), do: inspect(exception)

  defp format_error_and_stack(error, stack, luerl_state) do
    format_error(error, luerl_state) <> "\n" <>
    format_stack(stack, luerl_state) <> "\n"
  end

  defp format_stack(stack, luerl_state) do
    (stack
    |> Enum.map(&format_stack_line(&1, luerl_state))
    |> Enum.join("\n"))
  end


  #defp format_stack_line({"-no-name-", _, [file: "-no-file-", line: 1]}, _), do: ""
  defp format_stack_line({"-no-name-", _, [file: "-no-file-", line: line_nr]}, _) do
    "at #{line_nr}: ()"
  end
  defp format_stack_line({{:tref, _}, _function_args, [file: _, line: line_nr]}, _luerl_state) do
    "at #{line_nr}:"
  end
  defp format_stack_line({{Sandman.LuerlWrapper, _}, _function_args, _}, luerl_state) do
    "[internal]"
  end

  defp format_stack_line({function_name, function_args, [file: _, line: line_nr]}, luerl_state) do
    #"#{function_name}(#{format_lua_terms(function_args, luerl_state)}):#{line_nr}"
    "at #{line_nr}: #{function_name || "<nil>"}(#{format_lua_terms(function_args, luerl_state)})"
  end
  defp format_stack_line(unexpected, _luerl_state) do
    #"#{function_name}(#{format_lua_terms(function_args, luerl_state)}):#{line_nr}"
    inspect({"unexpected error (you should not see this)", unexpected})
  end


  defp format_lua_terms([], _), do: ""
  defp format_lua_terms(terms, luerl_state) do
    Enum.map(terms, fn term ->
      format_term(term, luerl_state)
    end)
    |> Enum.join(", ")
  end

  # TODO: what is this illega index?
  # some_table.no_key does not throw this error
  defp format_error({:illegal_index, table, key}, luerl_state) do
    table = format_term(table, luerl_state)
    key = format_term(key, luerl_state)
    "Table #{table} does not contain key #{key}"
  end


  defp format_error({:badarg, where, arguments}, luerl_state) do
    "badarg in #{format_term(where, luerl_state)}: #{format_term(arguments, luerl_state)}"
  end

  defp format_error({:illegal_value, where, val}, luerl_state) do
    "invalid value in #{format_term(where, luerl_state)}: #{format_term(val, luerl_state)}"
  end
  defp format_error({:illegal_value, val}, luerl_state) do
    "invalid value: #{format_term(val, luerl_state)}"
  end
  defp format_error({:illegal_comp, where}, luerl_state) do
    "illegal comparison in #{format_term(where, luerl_state)}"
  end
  defp format_error({:invalid_order, where}, luerl_state) do
    "invalid order function in #{format_term(where, luerl_state)}"
  end

  defp format_error({:undefined_function, name}, luerl_state) do
    "undefined function #{format_term(name, luerl_state)}"
  end
  defp format_error({:undefined_method, obj, name}, luerl_state) do
    "undefined method in #{format_term(obj, luerl_state)}: #{format_term(name, luerl_state)}"
  end

  defp format_error(:invalid_pattern, _),do: "malformed pattern"

  defp format_error(:invalid_capture, _), do: "malformed pattern"

  defp format_error({:invalid_char_class, char}, _luerl_state) do
    "malformed pattern: #{[char]}"
  end
  defp format_error(:invalid_char_set, _luerl_state), do: "malformed pattern (missing ']')"

  defp format_error({:illegal_op, operator}, luerl_state) do
    "illegal operator: #{format_term(operator, luerl_state)}"
  end
  defp format_error({:no_module, module}, luerl_state) do
    "module '#{format_term(module, luerl_state)}' not found"
  end
  defp format_error({type, message}, _luerl_state) when is_bitstring(type) and is_bitstring(message) do
    "#{type}: \"#{message}\""
  end
  defp format_error(err, _luerl_state) when is_bitstring(err) , do: err
  defp format_error(err, _luerl_state), do: inspect(err)

  defp format_term(term, luerl_state) when is_list(term) do
    try do
      decoded = :luerl_new.decode(term, luerl_state)
      format_to_lua(decoded)
    rescue _e ->
      IO.inspect({"WARN, COULD NOT ENCODE ERROR TERM", term})
      inspect(term)
    end
  end
  defp format_term(term, _luerl_state), do: inspect(term)

  defp format_to_lua(decoded) when is_list(decoded) do
    "{" <> (decoded
    |> Enum.map(fn {k, _v} -> k end)
    |> Enum.join(", ")) <> "}"
  end
  defp format_to_lua(decoded), do: inspect(decoded)

end



# Lua Error:{
#   {:illegal_index, nil, "val"},
#   [
#     {function_name, args, [file: _, line: line_nr]}
#     {"throwit", [], [file: "-no-file-", line: 3]},
#     {"test2", [], [file: "-no-file-", line: 6]},
#     {"-no-name-", [], [file: "-no-file-", line: 1]}
#   ]}


# Lua Error:{{:undefined_function, nil}, [{nil, [], [file: "-no-file-", line: 1]}, {"-no-name-", [], [file: "-no-file-", line: 1]}]}
# Lua Error:{{:undefined_function, nil}, [{nil, [], [file: "-no-file-", line: 1]}, {"-no-name-", [], [file: "-no-file-", line: 1]}]}
# Lua Error:{{:undefined_function, nil}, [{nil, [], [file: "-no-file-", line: 1]}, {"-no-name-", [], [file: "-no-file-", line: 1]}]}
# Lua Error:{{:undefined_function, nil}, [{nil, [], [file: "-no-file-", li
