defmodule Sandman.LuaApiDefinitionsTest do
  use ExUnit.Case, async: true
  alias Sandman.LuaApiDefinitions

  describe "get_api_definitions/0" do
    test "returns all API definitions" do
      definitions = LuaApiDefinitions.get_api_definitions()
      assert is_map(definitions)
      assert Map.has_key?(definitions, :print)
      assert Map.has_key?(definitions, :sandman)
    end
  end

  describe "type conversion" do
    test "converts top-level function params types to atoms" do
      {:ok, print_def} = LuaApiDefinitions.get_api_definition(["print"])
      assert print_def.schema.params == :any
    end

    test "converts sandman.getenv param types to atoms" do
      {:ok, getenv_def} = LuaApiDefinitions.get_api_definition(["sandman", "getenv"])

      assert length(getenv_def.schema.params) == 1
      [param] = getenv_def.schema.params
      assert param.name == "var_name"
      assert param.type == :string
      assert is_atom(param.type)

      assert length(getenv_def.schema.ret_vals) == 1
      [ret_val] = getenv_def.schema.ret_vals
      assert ret_val.name == "value"
      assert ret_val.type == :string
      assert is_atom(ret_val.type)
    end

    test "converts sandman.document.get param types to atoms" do
      {:ok, doc_get_def} = LuaApiDefinitions.get_api_definition(["sandman", "document", "get"])

      assert length(doc_get_def.schema.params) == 1
      [param] = doc_get_def.schema.params
      assert param.name == "key"
      assert param.type == :string
      assert is_atom(param.type)

      assert length(doc_get_def.schema.ret_vals) == 1
      [ret_val] = doc_get_def.schema.ret_vals
      assert ret_val.type == :any
      assert is_atom(ret_val.type)
    end

    test "converts sandman.document.set param types to atoms" do
      {:ok, doc_set_def} = LuaApiDefinitions.get_api_definition(["sandman", "document", "set"])

      assert length(doc_set_def.schema.params) == 2
      [param1, param2] = doc_set_def.schema.params
      assert param1.name == "key"
      assert param1.type == :string
      assert is_atom(param1.type)

      assert param2.name == "value"
      assert param2.type == :any
      assert is_atom(param2.type)
    end

    test "converts sandman.json.encode param types to atoms" do
      {:ok, encode_def} = LuaApiDefinitions.get_api_definition(["sandman", "json", "encode"])

      assert length(encode_def.schema.params) == 1
      [param] = encode_def.schema.params
      assert param.name == "value"
      assert param.type == :any
      assert is_atom(param.type)
      assert param.decode == true
      assert param.map == true
    end

    test "converts sandman.json.decode param and ret_val types to atoms" do
      {:ok, decode_def} = LuaApiDefinitions.get_api_definition(["sandman", "json", "decode"])

      assert length(decode_def.schema.params) == 1
      [param] = decode_def.schema.params
      assert param.name == "json_string"
      assert param.type == :string
      assert is_atom(param.type)

      assert length(decode_def.schema.ret_vals) == 1
      [ret_val] = decode_def.schema.ret_vals
      assert ret_val.name == "value"
      assert ret_val.type == :any
      assert is_atom(ret_val.type)
    end

    test "converts sandman.base64 functions param types to atoms" do
      {:ok, encode_def} = LuaApiDefinitions.get_api_definition(["sandman", "base64", "encode"])
      [param] = encode_def.schema.params
      assert param.type == :string
      assert is_atom(param.type)

      {:ok, decode_def} = LuaApiDefinitions.get_api_definition(["sandman", "base64", "decode"])
      [param] = decode_def.schema.params
      assert param.type == :string
      assert is_atom(param.type)

      {:ok, encode_url_def} = LuaApiDefinitions.get_api_definition(["sandman", "base64", "encode_url"])
      [param] = encode_url_def.schema.params
      assert param.type == :string
      assert is_atom(param.type)

      {:ok, decode_url_def} = LuaApiDefinitions.get_api_definition(["sandman", "base64", "decode_url"])
      [param] = decode_url_def.schema.params
      assert param.type == :string
      assert is_atom(param.type)
    end

    test "converts sandman.jwt.sign param types to atoms" do
      {:ok, sign_def} = LuaApiDefinitions.get_api_definition(["sandman", "jwt", "sign"])

      assert length(sign_def.schema.params) == 3
      [claims, secret, options] = sign_def.schema.params

      assert claims.name == "claims"
      assert claims.type == :table
      assert is_atom(claims.type)
      assert claims.decode == true
      assert claims.map == true

      assert secret.name == "secret"
      assert secret.type == :string
      assert is_atom(secret.type)

      assert options.name == "options"
      assert options.type == :table
      assert is_atom(options.type)
      assert options.decode == true
      assert options.map == true
    end

    test "converts sandman.jwt.decode param and ret_val types to atoms" do
      {:ok, decode_def} = LuaApiDefinitions.get_api_definition(["sandman", "jwt", "decode"])

      assert length(decode_def.schema.params) == 1
      [param] = decode_def.schema.params
      assert param.name == "token"
      assert param.type == :string
      assert is_atom(param.type)

      assert length(decode_def.schema.ret_vals) == 2
      [claims, header] = decode_def.schema.ret_vals
      assert claims.name == "claims"
      assert claims.type == :table
      assert is_atom(claims.type)

      assert header.name == "header"
      assert header.type == :table
      assert is_atom(header.type)
    end

    test "converts sandman.jwt.verify param and ret_val types to atoms" do
      {:ok, verify_def} = LuaApiDefinitions.get_api_definition(["sandman", "jwt", "verify"])

      assert length(verify_def.schema.params) == 3
      [token, secret, options] = verify_def.schema.params

      assert token.name == "token"
      assert token.type == :string
      assert is_atom(token.type)

      assert secret.name == "secret"
      assert secret.type == :string
      assert is_atom(secret.type)

      assert options.name == "options"
      assert options.type == :table
      assert is_atom(options.type)
    end

    test "converts sandman.uri.parse param and ret_val types to atoms" do
      {:ok, parse_def} = LuaApiDefinitions.get_api_definition(["sandman", "uri", "parse"])

      assert length(parse_def.schema.params) == 1
      [param] = parse_def.schema.params
      assert param.name == "uri"
      assert param.type == :string
      assert is_atom(param.type)

      assert length(parse_def.schema.ret_vals) == 1
      [ret_val] = parse_def.schema.ret_vals
      assert ret_val.name == "components"
      assert ret_val.type == :table
      assert is_atom(ret_val.type)
    end

    test "converts sandman.uri.tostring nested schema types to atoms" do
      {:ok, tostring_def} = LuaApiDefinitions.get_api_definition(["sandman", "uri", "tostring"])

      assert length(tostring_def.schema.params) == 1
      [param] = tostring_def.schema.params

      # Check main param type
      assert param.name == "components"
      assert param.type == :table
      assert is_atom(param.type)
      assert param.decode == true
      assert param.map == true

      # Check nested schema exists and all types are atoms
      assert is_map(param.schema)
      nested_schema = param.schema

      assert nested_schema["host"] == :string

      assert nested_schema["path"] == :string

      assert nested_schema["port"] == :integer

      assert nested_schema["scheme"] == :string
      assert nested_schema["userinfo"] == :string
      assert nested_schema["query"] == :any
      assert nested_schema["queryString"] == :string
    end

    test "converts sandman.uri.encode/decode param types to atoms" do
      {:ok, encode_def} = LuaApiDefinitions.get_api_definition(["sandman", "uri", "encode"])
      [param] = encode_def.schema.params
      assert param.type == :string
      assert is_atom(param.type)

      {:ok, decode_def} = LuaApiDefinitions.get_api_definition(["sandman", "uri", "decode"])
      [param] = decode_def.schema.params
      assert param.type == :string
      assert is_atom(param.type)
    end

    test "converts sandman.uri.encode_component/decode_component param types to atoms" do
      {:ok, encode_def} = LuaApiDefinitions.get_api_definition(["sandman", "uri", "encode_component"])
      [param] = encode_def.schema.params
      assert param.type == :string
      assert is_atom(param.type)

      {:ok, decode_def} = LuaApiDefinitions.get_api_definition(["sandman", "uri", "decode_component"])
      [param] = decode_def.schema.params
      assert param.type == :string
      assert is_atom(param.type)
    end
  end

  describe "error handling" do
    test "returns error for non-existent API definition" do
      assert {:error, "API definition not found", ["nonexistent"]} =
        LuaApiDefinitions.get_api_definition(["nonexistent"])
    end

    test "returns error for non-existent nested API definition" do
      assert {:error, "API definition not found", ["sandman", "nonexistent"]} =
        LuaApiDefinitions.get_api_definition(["sandman", "nonexistent"])
    end
  end

  describe "all functions have schemas or are tables" do
    test "sandman.http functions exist" do
      assert {:ok, %{type: "function"}} = LuaApiDefinitions.get_api_definition(["sandman", "http", "get"])
      assert {:ok, %{type: "function"}} = LuaApiDefinitions.get_api_definition(["sandman", "http", "post"])
      assert {:ok, %{type: "function"}} = LuaApiDefinitions.get_api_definition(["sandman", "http", "put"])
      assert {:ok, %{type: "function"}} = LuaApiDefinitions.get_api_definition(["sandman", "http", "delete"])
      assert {:ok, %{type: "function"}} = LuaApiDefinitions.get_api_definition(["sandman", "http", "patch"])
      assert {:ok, %{type: "function"}} = LuaApiDefinitions.get_api_definition(["sandman", "http", "head"])
      assert {:ok, %{type: "function"}} = LuaApiDefinitions.get_api_definition(["sandman", "http", "request"])
    end

    test "sandman.server functions exist" do
      assert {:ok, %{type: "function"}} = LuaApiDefinitions.get_api_definition(["sandman", "server", "start"])
      assert {:ok, %{type: "function"}} = LuaApiDefinitions.get_api_definition(["sandman", "server", "get"])
      assert {:ok, %{type: "function"}} = LuaApiDefinitions.get_api_definition(["sandman", "server", "post"])
      assert {:ok, %{type: "function"}} = LuaApiDefinitions.get_api_definition(["sandman", "server", "put"])
      assert {:ok, %{type: "function"}} = LuaApiDefinitions.get_api_definition(["sandman", "server", "delete"])
      assert {:ok, %{type: "function"}} = LuaApiDefinitions.get_api_definition(["sandman", "server", "patch"])
      assert {:ok, %{type: "function"}} = LuaApiDefinitions.get_api_definition(["sandman", "server", "head"])
      assert {:ok, %{type: "function"}} = LuaApiDefinitions.get_api_definition(["sandman", "server", "add_route"])
    end
  end
end
