defmodule Sandman.LuaApiDefinitions do
  @definitions_file Path.join(:code.priv_dir(:sandman), "api_definitions.json")

  # Load and cache the API definitions from JSON at compile time
  @external_resource @definitions_file
  @definitions (case File.read(@definitions_file) do
    {:ok, content} ->
      json = Jason.decode!(content, keys: :atoms)

      # Convert types to atoms inline - completely inline approach
      json
      |> Enum.map(fn {key, value} ->
        # Process each API definition
        converted_value =
          value
          # Handle schema params conversion
          |> (fn api_def ->
            case api_def do
              %{schema: %{params: "any"}} = def ->
                put_in(def[:schema][:params], :any)

              %{schema: %{params: params}} = def when is_list(params) ->
                atom_params = Enum.map(params, fn param ->
                  Map.update!(param, :type, &String.to_atom/1)
                end)
                put_in(def[:schema][:params], atom_params)

              def ->
                def
            end
          end).()
          # Handle schema ret_vals conversion
          |> (fn api_def ->
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
          end).()
          # Handle nested tables (recursive processing)
          |> (fn api_def ->
            Enum.reduce(api_def, %{}, fn {k, v}, acc ->
              case v do
                %{type: "table"} = table_def ->
                  # For nested tables, recursively process their children
                  nested_map = Map.drop(table_def, [:type, :description])
                  processed_nested = Enum.map(nested_map, fn {nested_key, nested_value} ->
                    # Process nested API definitions
                    processed_nested_value =
                      nested_value
                      # Handle nested schema params
                      |> (fn nested_def ->
                        case nested_def do
                          %{schema: %{params: "any"}} = def ->
                            put_in(def[:schema][:params], :any)

                          %{schema: %{params: params}} = def when is_list(params) ->
                            atom_params = Enum.map(params, fn param ->
                              Map.update!(param, :type, &String.to_atom/1)
                            end)
                            put_in(def[:schema][:params], atom_params)

                          def ->
                            def
                        end
                      end).()
                      # Handle nested ret_vals
                      |> (fn nested_def ->
                        case nested_def do
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
                      end).()

                    {nested_key, processed_nested_value}
                  end) |> Map.new()

                  Map.put(acc, k, Map.merge(table_def, processed_nested))

                other ->
                  Map.put(acc, k, other)
              end
            end)
          end).()

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
          Map.update!(param, :type, &String.to_atom/1)
        end)
        put_in(def[:schema][:params], atom_params)

      def ->
        def
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
