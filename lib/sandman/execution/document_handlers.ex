defmodule Sandman.DocumentHandlers do
  alias Sandman.HttpClient
  alias Sandman.LuerlWrapper
  alias Sandman.LuaApiDefinitions
  alias Sandman.Encoders.Base64
  alias Sandman.Encoders.Json
  alias Sandman.Encoders.Jwt
  alias Sandman.Encoders.Uri

  def build_handlers(self_pid, doc_id) do
    # TODO: refactor this so that req can be stored before request is being sent
    fetch_handler = fn [method | args], luerl_state ->
      decoded_args = :luerl.decode_list(args, luerl_state)
      {result, luerl_state} = HttpClient.fetch_handler(doc_id, method, decoded_args, luerl_state)
      call_info = LuerlWrapper.get_call_info(luerl_state)
      # send the result to the document
      GenServer.cast(self_pid, {:record_http_request, result, call_info, nil})
      # return with lua script
      {encoded_results, luerl_state} = Enum.reduce(result.lua_result, {[], luerl_state}, fn item, {encoded_results, luerl_state} ->
        {item_enc, luerl_state} = :luerl.encode(item, luerl_state)
        {encoded_results ++ [item_enc], luerl_state}
      end)
    end

    add_route_handler = fn [method | args], luerl_state ->
      call_info = LuerlWrapper.get_call_info(luerl_state)
        res = case GenServer.call(self_pid, {:handle_lua_call, :add_route, [method] ++ args, call_info}) do
          {:ok, res} ->
            res
          {:error, message} ->
            :luerl_lib.lua_error({:badarg, method, message}, luerl_state)
        end
        {res, luerl_state}
    end

    [
      {["sandman", "http", "get"], &fetch_handler.(["GET"] ++ &1, &2)},
      {["sandman", "http", "post"], &fetch_handler.(["POST"] ++ &1, &2)},
      {["sandman", "http", "put"], &fetch_handler.(["PUT"] ++ &1, &2)},
      {["sandman", "http", "delete"], &fetch_handler.(["DELETE"] ++ &1, &2)},
      {["sandman", "http", "patch"], &fetch_handler.(["PATCH"] ++ &1, &2)},
      {["sandman", "http", "head"], &fetch_handler.(["HEAD"] ++ &1, &2)},
      {["sandman", "http", "send"], &fetch_handler.(&1, &2)},
      {["print"],fn args, luerl_state ->
        decoded_args = :luerl.decode_list(args, luerl_state)
        {:ok, res} = GenServer.call(self_pid, {:handle_lua_call, :print, decoded_args})
        {res, luerl_state}
      end},

      {["sandman", "server", "start"], fn port, luerl_state ->
        {:ok, res} = GenServer.call(self_pid, {:handle_lua_call, :start_server, port})
        {res, luerl_state}
      end},
      {["sandman", "server", "get"], &add_route_handler.(["GET"] ++ &1, &2)},
      {["sandman", "server", "post"], &add_route_handler.(["POST"] ++ &1, &2)},
      {["sandman", "server", "put"], &add_route_handler.(["PUT"] ++ &1, &2)},
      {["sandman", "server", "delete"], &add_route_handler.(["DELETE"] ++ &1, &2)},
      {["sandman", "server", "patch"], &add_route_handler.(["PATCH"] ++ &1, &2)},
      {["sandman", "server", "head"], &add_route_handler.(["HEAD"] ++ &1, &2)},
      {["sandman", "server", "add_route"], &add_route_handler.(&1, &2)},
      {["sandman", "document", "set"], fn [key, val], luerl_state ->
        decoded_val = :luerl.decode(val, luerl_state)
        {:ok, res} = GenServer.call(self_pid, {:handle_lua_call, :document_set, [key, decoded_val]})
        {res, luerl_state}
      end},
      {["sandman", "document", "get"],fn [key], luerl_state ->
        {:ok, decoded_res} = GenServer.call(self_pid, {:handle_lua_call, :document_get, [key]})
        {res, luerl_state} = :luerl.encode(decoded_res, luerl_state)
        {[res], luerl_state}
      end},

      {["sandman", "json", "decode"], &Json.decode(doc_id, &1, &2)},
      {["sandman", "json", "encode"], &Json.encode(doc_id, &1, &2)},
      {["sandman", "base64", "decode"], &Base64.decode(doc_id, &1, &2)},
      {["sandman", "base64", "encode"], &Base64.encode(doc_id, &1, &2)},
      {["sandman", "base64", "decode_url"], &Base64.decode_url(doc_id, &1, &2)},
      {["sandman", "base64", "encode_url"], &Base64.encode_url(doc_id, &1, &2)},
      {["sandman", "jwt", "sign"], &Jwt.sign(doc_id, &1, &2)},
      {["sandman", "jwt", "verify"], &Jwt.verify(doc_id, &1, &2)},
      {["sandman", "uri", "parse"], &LuaSupport.Uri.parse(doc_id, &1, &2)},
      {["sandman", "uri", "tostring"], &LuaSupport.Uri.tostring(doc_id, &1, &2)},
      {["sandman", "uri", "encode"], &LuaSupport.Uri.encode(doc_id, &1, &2)},
      {["sandman", "uri", "decode"], &LuaSupport.Uri.decode(doc_id, &1, &2)},
      {["sandman", "uri", "encodeComponent"], &LuaSupport.Uri.encodeComponent(doc_id, &1, &2)},
      {["sandman", "uri", "decodeComponent"], &LuaSupport.Uri.decodeComponent(doc_id, &1, &2)},
     ] |> wrap_handlers()
  end

  defp wrap_handlers(handlers) do
    handlers |>
    Enum.map(
      fn
        {path, handler} ->
          {:ok, api_def} = LuaApiDefinitions.get_api_definition(path)
          IO.inspect({"api definition", api_def})
          wrapped_handler = wrap_handler(path, handler, api_def)
          {path, wrapped_handler}
      end)
  end

  @default_schema %{
    params: :any,
    ret_vals: :any
  }

  defp wrap_handler(path, handler, api_def = %{type: :function}) do
    full_function_name = Enum.join(path, ".")

    schema = api_def[:schema] || @default_schema
    params = schema.params

    wrapped_handler = fn args, luerl_state ->
      # test number of args
      if(params == :any || length(params) == length(args)) do
        case validate_args(args, params, full_function_name) do
          [] ->
            try do
              handler.(args, luerl_state)
            rescue
              error ->
                :luerl_lib.lua_error("Invalid arguments for #{full_function_name}", luerl_state)
            end
          [err | _] -> :luerl_lib.lua_error(err, luerl_state)
        end
      else
        :luerl_lib.lua_error("Invalid number of arguments for '#{full_function_name}' expected: (#{format_params(params)})", luerl_state)
      end
    end
  end

  defp format_params(params) do
    params
    |> Enum.map(fn %{type: type} -> type end)
    |> Enum.join(", ")
  end

  defp validate_args(_, :any, _), do: []
  defp validate_args(args, params, full_function_name) do
    args
    |> Enum.zip(params)
    |> Enum.with_index
    |> Enum.reduce([], fn {{arg, param}, index}, acc ->
      IO.inspect({"validate_args", {param, arg}, index})
      if param == :any || arg_type(arg) == param.type do
        acc
      else
        acc ++ ["Bad argument ##{index + 1} to '#{full_function_name}' (expected #{param.type}, got #{type_to_string(arg_type(arg))})"]
      end
    end)
  end

  defp arg_type(nil), do: :nil
  defp arg_type(arg) when is_number(arg), do: :number
  defp arg_type(arg) when is_bitstring(arg), do: :string
  defp arg_type(arg) when is_boolean(arg), do: :boolean
  defp arg_type({:tref, _}), do: :table
  defp arg_type({:erl_func, _}), do: :function
  defp arg_type({:funref, _, _}), do: :function
  defp arg_type(arg) do
    IO.inspect({"unhandled arg type", arg})
    :unknown
  end

  def type_to_string(type) do
    case type do
      :nil -> "nil"
      :number -> "number"
      :string -> "string"
      :boolean -> "boolean"
      :table -> "table"
      :function -> "function"
      :unknown -> "unknown"
    end
  end
  # likely unmatched for functions, coroutines/threads, TODO

end
