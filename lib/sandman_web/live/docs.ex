defmodule SandmanWeb.LiveView.Docs do
  use Phoenix.Component

  def render(assigns) do
    api_definitions = Sandman.LuaApiDefinitions.get_api_definitions()
    functions = flatten_api_definitions(api_definitions, [])
    grouped_functions = group_by_namespace(functions)

    assigns = assigns
    |> assign(:grouped_functions, grouped_functions)

    ~H"""
    <div class="h-full flex flex-col bg-neutral-800">
      <div class="flex-1 overflow-y-auto p-4">
        <div class="space-y-6">
          <div class="border-b border-neutral-600 pb-3">
            <h2 class="text-lg font-semibold text-neutral-100">Lua API Documentation</h2>
            <p class="text-sm text-neutral-400 mt-1">Available functions and their parameters</p>
          </div>

          <div class="space-y-4">
            <%= for {namespace, functions} <- @grouped_functions do %>
              <% is_expanded = MapSet.member?(@docs_expanded_namespaces, namespace) %>
              <div class="border border-neutral-600 rounded-lg overflow-hidden">
                <button
                  class="w-full bg-neutral-700 px-4 py-2 border-b border-neutral-600 hover:bg-neutral-650 transition-colors text-left flex items-center justify-between"
                  phx-click="toggle-docs-namespace"
                  phx-value-namespace={namespace}
                >
                  <h3 class="text-sm font-medium text-neutral-100"><%= namespace %></h3>
                  <div class={"text-neutral-400 transition-transform duration-200 #{if is_expanded, do: "rotate-90", else: ""}"}>
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"></path>
                    </svg>
                  </div>
                </button>
                <%= if is_expanded do %>
                  <div class="divide-y divide-neutral-600">
                    <%= for func <- functions do %>
                      <% function_id = func.name %>
                      <% is_function_expanded = MapSet.member?(@docs_expanded_functions, function_id) %>
                      <% has_details = length(func.params) > 0 or length(func.return_values) > 0 %>

                      <div class="hover:bg-neutral-750">
                        <div class="p-4">
                          <div class="flex items-start justify-between">
                            <div class="flex-1">
                              <div class="flex items-center gap-2 mb-1">
                                <%= if has_details do %>
                                  <button
                                    class="flex items-center gap-2 text-left hover:bg-neutral-700 rounded px-1 py-0.5 transition-colors group"
                                    phx-click="toggle-docs-function"
                                    phx-value-function={function_id}
                                    title="Toggle parameters and return values"
                                  >
                                    <code class="text-blue-400 font-mono text-sm group-hover:text-blue-300"><%= List.last(func.path) %></code>
                                    <div class={"text-neutral-400 group-hover:text-neutral-200 transition-all duration-200 #{if is_function_expanded, do: "rotate-90", else: ""}"}>
                                      <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"></path>
                                      </svg>
                                    </div>
                                  </button>
                                <% else %>
                                  <code class="text-blue-400 font-mono text-sm"><%= List.last(func.path) %></code>
                                <% end %>
                                <span class="text-xs text-neutral-500 bg-neutral-700 px-2 py-0.5 rounded">function</span>
                                <%= if func.has_try do %>
                                  <span class="text-xs text-amber-200 bg-amber-800 px-2 py-0.5 rounded ml-1" title="This function can throw errors">throws</span>
                                <% end %>
                              </div>
                              <p class="text-sm text-neutral-300 mb-2"><%= func.description %></p>

                              <%= if has_details and is_function_expanded do %>
                                <div class="mt-3 space-y-3 pl-4 border-l-2 border-neutral-600">
                                  <%= if func.has_try do %>
                                    <div class="mb-3 p-2 bg-amber-900/20 border border-amber-600/30 rounded text-xs">
                                      <strong class="text-amber-200">⚠️ Note:</strong> <span class="text-amber-200">This function can throw errors. A</span> <code class="text-amber-300 bg-amber-900/30 px-1 rounded">try_<%= List.last(func.path) %></code> <span class="text-amber-200">alternative is available that returns</span> <code class="text-amber-300 bg-amber-900/30 px-1 rounded">nil, reason</code> <span class="text-amber-200">instead of throwing.</span>
                                    </div>
                                  <% end %>

                                  <%= if length(func.params) > 0 do %>
                                    <div>
                                      <span class="text-xs text-neutral-400 uppercase tracking-wide">Parameters:</span>
                                      <div class="text-sm text-neutral-300 font-mono mt-1">
                                        <%= Enum.map_join(func.params, ", ", fn p ->
                                          if p.name, do: "#{p.name}: #{p.type}", else: "#{p.type}"
                                        end) %>
                                      </div>
                                    </div>
                                  <% end %>

                                  <%= if length(func.return_values) > 0 do %>
                                    <div>
                                      <span class="text-xs text-neutral-400 uppercase tracking-wide">Returns:</span>
                                      <div class="text-sm text-neutral-300 font-mono mt-1">
                                        <%= Enum.map_join(func.return_values, ", ", fn r -> r.type end) %>
                                      </div>
                                    </div>
                                  <% end %>

                                  <%= if length(func.params) > 0 do %>
                                    <div>
                                      <span class="text-xs text-neutral-400 uppercase tracking-wide">Example:</span>
                                      <div class="text-sm text-neutral-300 font-mono mt-1 bg-neutral-900 rounded p-2 border border-neutral-700">
                                        <%= generate_example(func) %>
                                        <%= if func.has_try do %>
                                          <br /><span class="text-neutral-500">-- Safe alternative:</span><br />
                                          <%= generate_try_example(func) %>
                                        <% end %>
                                      </div>
                                    </div>
                                  <% end %>
                                </div>
                              <% end %>
                            </div>
                          </div>
                        </div>
                      </div>
                    <% end %>
                  </div>
                <% end %>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp flatten_api_definitions(definitions, path_acc) when is_map(definitions) do
    definitions
    |> Enum.flat_map(fn {key, value} ->
      current_path = path_acc ++ [key]
      case value do
        %{type: :function} = func_def ->
          [format_function_doc(current_path, func_def)]
        %{type: :table} = table_def ->
          # Remove the :type key and recurse into the table
          table_contents = Map.delete(table_def, :type)
          flatten_api_definitions(table_contents, current_path)
        _ ->
          []
      end
    end)
  end

  defp flatten_api_definitions(_, _), do: []

  defp format_function_doc(path, func_def) do
    full_name = Enum.join(path, ".")

    %{
      name: full_name,
      path: path,
      type: "function",
      params: extract_params(func_def),
      return_values: extract_return_values(func_def),
      description: Map.get(func_def, :description, "Lua API function"),
      has_try: Map.get(func_def, :has_try, false)
    }
  end

  defp extract_params(%{schema: %{params: params}}) when is_list(params) do
    params
    |> Enum.map(fn param ->
      %{
        name: Map.get(param, :name),
        type: Map.get(param, :type, "any"),
        required: true
      }
    end)
  end

  defp extract_params(_), do: []

  defp extract_return_values(%{schema: %{ret_vals: ret_vals}}) when is_list(ret_vals) do
    ret_vals
    |> Enum.with_index()
    |> Enum.map(fn {ret_val, idx} ->
      %{
        name: Map.get(ret_val, :name) || "return#{idx + 1}",
        type: Map.get(ret_val, :type, "any")
      }
    end)
  end

  defp extract_return_values(_), do: []


  defp group_by_namespace(functions) do
    functions
    |> Enum.group_by(fn func ->
      if length(func.path) > 1 do
        func.path |> Enum.slice(0..-2) |> Enum.join(".")
      else
        "Global"
      end
    end)
    |> Enum.sort_by(fn {namespace, _} -> namespace end)
  end

  defp generate_example(func) do
    function_name = func.name
    param_examples = generate_param_examples(func.params)

    function_call = if length(param_examples) > 0 do
      "#{function_name}(#{Enum.join(param_examples, ", ")})"
    else
      "#{function_name}()"
    end

    # Add assignment if there are return values
    if length(func.return_values) > 0 do
      return_vars = generate_return_variables(func.return_values)
      "#{return_vars} = #{function_call}"
    else
      function_call
    end
  end

  defp generate_param_examples(params) do
    params
    |> Enum.map(fn param ->
      example_value = case param.type do
        :string -> "\"some string\""
        :number -> "42"
        :boolean -> "true"
        :table -> "{key = \"value\"}"
        _ -> "value"
      end

      # If parameter has a name, use it as a comment or in the example
      if param.name do
        case param.type do
          :string -> "\"#{param.name}\""
          _ -> example_value
        end
      else
        example_value
      end
    end)
  end

  defp generate_try_example(func) do
    function_name = func.name
    param_examples = generate_param_examples(func.params)

    # Replace the last part of the function name with try_ prefix
    path_parts = func.path
    last_part = List.last(path_parts)
    try_path = List.replace_at(path_parts, -1, "try_#{last_part}")
    try_function_name = Enum.join(try_path, ".")

    function_call = if length(param_examples) > 0 do
      "#{try_function_name}(#{Enum.join(param_examples, ", ")})"
    else
      "#{try_function_name}()"
    end

    # Generate return variables with _or_nil and _or_error suffixes
    return_vars = generate_try_return_variables(func.return_values)
    "#{return_vars} = #{function_call}"
  end

  defp generate_return_variables(return_values) do
    return_values
    |> Enum.map(fn ret_val ->
      ret_val.name || "result"
    end)
    |> Enum.join(", ")
  end

  defp generate_try_return_variables(return_values) do
    case return_values do
      [] ->
        "result_or_nil, error_or_reason"
      [first_ret | rest] ->
        first_var = "#{first_ret.name || "result"}_or_nil"
        second_var = "#{first_ret.name || "result"}_or_error"

        # If there are more return values, include them
        additional_vars = rest
        |> Enum.map(fn ret_val ->
          "#{ret_val.name || "result"}_or_nil"
        end)

        ([first_var, second_var] ++ additional_vars)
        |> Enum.join(", ")
    end
  end
end
