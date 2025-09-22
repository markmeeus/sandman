defmodule Sandman.LuaApiDefinitions do
  def get_api_definitions() do
    %{
      print: %{
        type: :function,
        description: "Prints values to the console/logs",
        schema: %{
          params: :any
        }
      },
      sandman: %{
        type: :table,
        http: %{
          type: :table,
          get: %{
            type: :function,
            description: "Makes an HTTP GET request"
          },
          post: %{
            type: :function,
            description: "Makes an HTTP POST request"
          },
          put: %{
            type: :function,
            description: "Makes an HTTP PUT request"
          },
          delete: %{
            type: :function,
            description: "Makes an HTTP DELETE request"
          },
          patch: %{
            type: :function,
            description: "Makes an HTTP PATCH request"
          },
          head: %{
            type: :function,
            description: "Makes an HTTP HEAD request"
          },
          send: %{
            type: :function,
            description: "Sends an HTTP request with custom configuration"
          }
        },
        server: %{
          type: :table,
          start: %{
            type: :function,
            description: "Starts the HTTP server"
          },
          get: %{
            type: :function,
            description: "Handles HTTP GET requests on the server"
          },
          post: %{
            type: :function,
            description: "Handles HTTP POST requests on the server"
          },
          put: %{
            type: :function,
            description: "Handles HTTP PUT requests on the server"
          },
          delete: %{
            type: :function,
            description: "Handles HTTP DELETE requests on the server"
          },
          patch: %{
            type: :function,
            description: "Handles HTTP PATCH requests on the server"
          },
          head: %{
            type: :function,
            description: "Handles HTTP HEAD requests on the server"
          },
          add_route: %{
            type: :function,
            description: "Adds a route to the HTTP server"
          }
        },
        document: %{
          type: :table,
          set: %{
            type: :function,
            description: "Sets a value in the document context",
            schema: %{
              params: [%{type: :string, name: "key"}, %{type: :any, name: "value"}],
              ret_vals: []
            }
          },
          get: %{
            type: :function,
            description: "Gets a value from the document context",
            schema: %{params: [%{type: :string, name: "key"}], ret_vals: [%{type: :any}]}
          }
        },
        json: %{
          type: :table,
          decode: %{
            type: :function,
            description: "Decodes a JSON string into a Lua table"
          },
          encode: %{
            type: :function,
            description: "Encodes a Lua table into a JSON string"
          }
        },
        base64: %{
          type: :table,
          decode: %{
            type: :function,
            description: "Decodes a base64 string",
            schema: %{params: [%{type: :string}], ret_vals: [%{type: :string}]}
          },
          encode: %{
            type: :function,
            description: "Encodes a string to base64",
            schema: %{params: [%{type: :string}], ret_vals: [%{type: :string}]}
          },
          decode_url: %{
            type: :function,
            description: "Decodes a URL-safe base64 string",
            schema: %{params: [%{type: :string}], ret_vals: [%{type: :string}]}
          },
          encode_url: %{
            type: :function,
            description: "Encodes a string to URL-safe base64",
            schema: %{params: [%{type: :string}], ret_vals: [%{type: :string}]}
          }
        },
        jwt: %{
          type: :table,
          sign: %{
            type: :function,
            description: "Signs a JWT token"
          },
          verify: %{
            type: :function,
            description: "Verifies a JWT token"
          }
        },
        uri: %{
          type: :table,
          parse: %{
            type: :function,
            description: "Parses a URI string into components"
          },
          tostring: %{
            type: :function,
            description: "Converts URI components to a string"
          },
          encode: %{
            type: :function,
            description: "URL-encodes a string"
          },
          decode: %{
            type: :function,
            description: "URL-decodes a string"
          },
          encodeComponent: %{
            type: :function,
            description: "URL-encodes a string component"
          },
          decodeComponent: %{
            type: :function,
            description: "URL-decodes a string component"
          }
        }
      }
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
