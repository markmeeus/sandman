defmodule Sandman.LuaApiDefinitions do
  @definitions_file Path.join(:code.priv_dir(:sandman), "api_definitions.json")

  # Load and cache the API definitions from JSON at compile time
  @external_resource @definitions_file
  @definitions (case File.read(@definitions_file) do
    {:ok, content} ->
      json = Jason.decode!(content, keys: :atoms)

      # Helper function to convert nested schema inside params
      convert_nested_param_schema = fn param ->
        case param do
          %{schema: schema} when is_map(schema) ->
            # Convert each value in the nested schema from string to atom
            converted_schema = Enum.map(schema, fn {key, value} ->
              atom_value = if is_binary(value), do: String.to_atom(value), else: value
              {key, atom_value}
            end) |> Map.new()
            Map.put(param, :schema, converted_schema)

          param ->
            param
        end
      end

      # Helper function to convert params list
      convert_params = fn
        "any" -> :any
        params when is_list(params) ->
          Enum.map(params, fn param ->
            param
            |> Map.update!(:type, &String.to_atom/1)
            |> convert_nested_param_schema.()
          end)
        other -> other
      end

      # Helper function to convert ret_vals list
      convert_ret_vals = fn
        "any" -> :any
        ret_vals when is_list(ret_vals) ->
          Enum.map(ret_vals, fn ret_val ->
            Map.update!(ret_val, :type, &String.to_atom/1)
          end)
        other -> other
      end

      # Helper function to process an API definition (function)
      process_api_def = fn api_def ->
        api_def
        |> then(fn def ->
          case def do
            %{schema: %{params: params}} = d ->
              put_in(d[:schema][:params], convert_params.(params))
            d -> d
          end
        end)
        |> then(fn def ->
          case def do
            %{schema: %{ret_vals: ret_vals}} = d ->
              put_in(d[:schema][:ret_vals], convert_ret_vals.(ret_vals))
            d -> d
          end
        end)
      end

      # Helper function to process nested items (children of tables)
      process_nested_items = fn items ->
        Enum.map(items, fn {key, value} ->
          {key, process_api_def.(value)}
        end)
        |> Map.new()
      end

      # Process the entire JSON structure
      json
      |> Enum.map(fn {key, value} ->
        converted_value = case value do
          # Top-level tables (like "sandman")
          %{type: "table"} = table_def ->
            # Get all children (non-metadata fields)
            children = Map.drop(table_def, [:type, :description])

            # Process children recursively
            processed_children = Enum.map(children, fn {child_key, child_value} ->
              processed_child = case child_value do
                # Nested table (like "sandman.http", "sandman.json")
                %{type: "table"} = nested_table ->
                  nested_children = Map.drop(nested_table, [:type, :description])
                  processed_nested = process_nested_items.(nested_children)
                  Map.merge(nested_table, processed_nested)

                # Direct function child (like "sandman.getenv")
                other ->
                  process_api_def.(other)
              end

              {child_key, processed_child}
            end)
            |> Map.new()

            Map.merge(table_def, processed_children)

          # Top-level functions (like "print")
          other ->
            process_api_def.(other)
        end

        {key, converted_value}
      end)
      |> Map.new()

    {:error, _} ->
      raise "Could not load API definitions from #{@definitions_file}"
  end)

  def get_api_definitions() do
    @definitions
  end

  def get_api_definition(path) do
    atom_path = path |> Enum.map(&String.to_atom/1)

    get_api_definitions()
    |> get_in(atom_path)
    |> case do
      nil ->
        {:error, "API definition not found", path}

      definition ->
        {:ok, definition}
    end
  end

  # Public function for external use (uses runtime conversion)
  def convert_types_to_atoms(json) when is_map(json) do
    json
    |> Enum.map(fn {key, value} ->
      {key, convert_api_def_types(value)}
    end)
    |> Map.new()
  end

  defp convert_api_def_types(api_def) when is_map(api_def) do
    api_def
    |> convert_schema_types()
    |> convert_ret_vals_types()
    |> convert_nested_tables()
  end

  defp convert_schema_types(api_def) do
    case api_def do
      %{schema: %{params: "any"}} = def ->
        put_in(def[:schema][:params], :any)

      %{schema: %{params: params}} = def when is_list(params) ->
        atom_params = Enum.map(params, fn param ->
          param
          |> Map.update!(:type, &String.to_atom/1)
          |> convert_nested_param_schema_runtime()
        end)
        put_in(def[:schema][:params], atom_params)

      def ->
        def
    end
  end

  defp convert_nested_param_schema_runtime(param) do
    case param do
      %{schema: schema} when is_map(schema) ->
        # Convert each value in the nested schema from string to atom
        converted_schema = Enum.map(schema, fn {key, value} ->
          atom_value = if is_binary(value), do: String.to_atom(value), else: value
          {key, atom_value}
        end) |> Map.new()
        Map.put(param, :schema, converted_schema)

      param ->
        param
    end
  end

  defp convert_ret_vals_types(api_def) do
    case api_def do
      %{schema: %{ret_vals: "any"}} = def ->
        put_in(def[:schema][:ret_vals], :any)

      %{schema: %{ret_vals: ret_vals}} = def when is_list(ret_vals) ->
        atom_ret_vals = Enum.map(ret_vals, fn ret_val ->
          Map.update!(ret_val, :type, &String.to_atom/1)
        end)
        put_in(def[:schema][:ret_vals], atom_ret_vals)

      def ->
        def
    end
  end

  defp convert_nested_tables(api_def) do
    Enum.reduce(api_def, %{}, fn {key, value}, acc ->
      case value do
        %{type: "table"} = table_def ->
          # Recursively process nested table definitions
          nested_converted = Map.drop(table_def, [:type, :description])
                             |> Enum.map(fn {k, v} -> {k, convert_api_def_types(v)} end)
                             |> Map.new()
          Map.put(acc, key, Map.merge(table_def, nested_converted))

        other ->
          Map.put(acc, key, other)
      end
    end)
  end
end
