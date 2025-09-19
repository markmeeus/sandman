defmodule Sandman.LuaApiDefinitions do
  def get_api_definitions() do
    %{
      print: %{
        type: :function,
        schema: %{
          params: :any
        }
      },
      sandman: %{
        type: :table,
        http: %{
          type: :table,
          get: %{
            type: :function
          },
          post: %{
            type: :function
          },
          put: %{
            type: :function
          },
          delete: %{
            type: :function
          },
          patch: %{
            type: :function
          },
          head: %{type: :function},
          send: %{type: :function},
        },
        server: %{
          type: :table,
          start: %{
            type: :function
          },
          get: %{type: :function},
          post: %{type: :function},
          put: %{type: :function},
          delete: %{type: :function},
          patch: %{type: :function},
          head: %{type: :function},
          add_route: %{type: :function},
        },
        document: %{
          type: :table,
          set: %{type: :function},
          get: %{type: :function},
        },
        json: %{
          type: :table,
          decode: %{type: :function},
          encode: %{type: :function},
        },
        base64: %{
          type: :table,
          decode: %{type: :function, schema: %{params: [%{type: :string}], ret_vals: [%{type: :string}]}},
          encode: %{type: :function, schema: %{params: [%{type: :string}], ret_vals: [%{type: :string}]}},
          decode_url: %{type: :function, schema: %{params: [%{type: :string}], ret_vals: [%{type: :string}]}},
          encode_url: %{type: :function, schema: %{params: [%{type: :string}], ret_vals: [%{type: :string}]}},
        },
        jwt: %{
          type: :table,
          sign: %{type: :function},
          verify: %{type: :function},
        },
        uri: %{
          type: :table,
          parse: %{type: :function},
          tostring: %{type: :function},
          encode: %{type: :function},
          decode: %{type: :function},
          encodeComponent: %{type: :function},
          decodeComponent: %{type: :function},
        },
      },
    }
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
end
