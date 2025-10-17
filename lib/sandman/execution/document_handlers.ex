defmodule Sandman.DocumentHandlers do
  alias Sandman.HttpClient
  alias Sandman.LuerlWrapper
  alias Sandman.LuaApiDefinitions
  alias Sandman.Encoders.Base64
  alias Sandman.Encoders.Json
  alias Sandman.LuaSupport.Jwt
  alias Sandman.LuaSupport.Uri

  alias Sandman.LuaMapper

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
      {encoded_results, luerl_state}
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
      {["sandman", "http", "request"], &fetch_handler.(&1, &2)},
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
      {["sandman", "jwt", "decode"], &Jwt.decode(doc_id, &1, &2)},
      {["sandman", "uri", "parse"], &Uri.parse(doc_id, &1, &2)},
      {["sandman", "uri", "tostring"], &Uri.tostring(doc_id, &1, &2)},
      {["sandman", "uri", "encode"], &Uri.encode(doc_id, &1, &2)},
      {["sandman", "uri", "decode"], &Uri.decode(doc_id, &1, &2)},
      {["sandman", "uri", "encode_component"], &Uri.encode_component(doc_id, &1, &2)},
      {["sandman", "uri", "decode_component"], &Uri.decode_component(doc_id, &1, &2)},
     ] |> wrap_handlers()
  end

  defp wrap_handlers(handlers) do
    handlers
    |> Enum.flat_map(fn {path, handler} ->
      {:ok, api_def} = LuaApiDefinitions.get_api_definition(path)
      wrapped_handler = wrap_handler(path, handler, api_def, false)

      base_handlers = [{path, wrapped_handler}]

      # If the function has has_try: true, also create a try_ version
      if Map.get(api_def, :has_try, false) do
        try_path = create_try_path(path)
        safe_wrapped_handler = wrap_handler(path, handler, api_def, true)
        base_handlers ++ [{try_path, safe_wrapped_handler}]
      else
        base_handlers
      end
    end)
  end

  @default_schema %{
    params: :any,
    ret_vals: :any
  }

  defp create_try_path(path) do
    # Replace the last element with try_ prefixed version
    last_element = List.last(path)
    List.replace_at(path, -1, "try_#{last_element}")
  end

  defp wrap_handler(path, handler, api_def = %{type: "function"}, safe_call) do
    full_function_name = Enum.join(path, ".")

    schema = api_def[:schema] || @default_schema
    params = schema.params

    fn args, luerl_state ->
      IO.inspect({"wrap_handler", path, api_def, safe_call})
      # test number of args
      if(params == :any || length(params) == length(args)) do
        case preprocess_args(args, params, full_function_name, luerl_state) do
          {:error, errors} ->
            if safe_call do
              {nil_val, luerl_state} = :luerl.encode(nil, luerl_state)
              {error_val, luerl_state} = :luerl.encode(errors, luerl_state)
              {[nil_val, error_val], luerl_state}
            else
              :luerl_lib.lua_error(errors, luerl_state)
            end
          args ->
            _res = try do
                IO.inspect({"calling handler", full_function_name, handler, args})
                handler.(args, luerl_state)
              rescue
                error ->
                  if safe_call do
                    {nil_val, luerl_state} = :luerl.encode(nil, luerl_state)
                    {error_val, luerl_state} = :luerl.encode("Invalid arguments for #{full_function_name}, #{inspect(error)}", luerl_state)
                    {[nil_val, error_val], luerl_state}
                  else
                    IO.inspect(error)
                    # this should actually not happen.
                    # the handlers should not throw, but return {:error, message, luerl_state}
                    :luerl_lib.lua_error("Invalid arguments for #{full_function_name}, #{inspect(error)}", luerl_state)
                  end
              end
              |> case do
                {:error, message, luerl_state} ->
                  if safe_call do
                    {nil_val, luerl_state} = :luerl.encode(nil, luerl_state)
                    {error_val, luerl_state} = :luerl.encode(message, luerl_state)
                    {[nil_val, error_val], luerl_state}
                  else
                    :luerl_lib.lua_error(message, luerl_state)
                  end
                {returns, luerl_state} ->
                  if(api_def[:schema][:ret_vals]) do
                    map_returns(returns, api_def[:schema][:ret_vals], luerl_state)
                  else
                    {returns, luerl_state}
                  end
              end

        end
      else
        if safe_call do
          {nil_val, luerl_state} = :luerl.encode(nil, luerl_state)
          {error_val, luerl_state} = :luerl.encode("Invalid number of arguments (#{format_args(args)}) for '#{full_function_name}' expected (#{format_params(params)})", luerl_state)
          {[nil_val, error_val], luerl_state}
        else
          :luerl_lib.lua_error("Invalid number of arguments (#{format_args(args)}) for '#{full_function_name}' expected (#{format_params(params)})", luerl_state)
        end
      end
    end
  end

  defp wrap_handler(path, _handler, api_def , safe_call) do
      IO.inspect({"unexpecte handler", path, api_def, safe_call})
      nil
  end

  defp map_returns(returns, ret_vals, luerl_state) do
    Enum.zip(returns, ret_vals)
    |> Enum.reduce({[], luerl_state}, fn {return, ret_val}, {encoded_returns, luerl_state} ->
      {encoded_return, luerl_state} = map_return(return, ret_val, luerl_state)
      {encoded_returns ++ [encoded_return], luerl_state}
    end)
  end

  defp map_return(return, ret_val, luerl_state) do
    {encoded, luerl_state} = if ret_val[:encode] do
      :luerl.encode(return, luerl_state)
    else
      {return, luerl_state}
    end
    mapped =if ret_val[:map] do
      LuaMapper.reverse_map(encoded)
    else
      encoded
    end
    {mapped, luerl_state}
  end

  defp preprocess_args(args, params, full_function_name, luerl_state) do
    case validate_args(args, params, full_function_name) do
      [] ->
        IO.inspect({"preprocessing args", args, params})
        map_args(args, params, luerl_state)
        |> IO.inspect()
      errors ->
        IO.inspect({"errors", errors})
        {:error, Enum.join(errors, ", ")}
    end
  end

  defp map_args(args, :any, _luerl_state), do: args
  defp map_args(args, params, luerl_state) do
    Enum.zip(args, params)
    |> Enum.map(fn {arg, param} ->
      decode_arg(arg, param, luerl_state)
      |> map_arg(param)
    end)
  end

  defp decode_arg(arg, param, luerl_state) do
    if param[:decode] do
      :luerl.decode(arg, luerl_state)
    else
      arg
    end
  end

  defp map_arg(arg, param) do
    if param[:map] do
      {mapped, warnings} =LuaMapper.map(arg, param[:schema] || :any)
      # todo, handle warnings here
      # but schemas are loaded from json and attributes into atom
      mapped
    else
      arg
    end
  end

  defp validate_args(_, :any, _), do: []
  defp validate_args(args, params, full_function_name) do
    args
    |> Enum.zip(params)
    |> Enum.with_index
    |> Enum.reduce([], fn {{arg, param}, index}, acc ->
      if param.type == :any || arg_type(arg) == param.type do
        acc
      else
        acc ++ ["Bad argument ##{index + 1} to '#{full_function_name}' expected #{param.type}, got #{type_to_string(arg_type(arg))})"]
      end
    end)
  end

  defp format_params(params) do
    params
    |> Enum.map(fn %{type: type} -> type end)
    |> Enum.join(", ")
  end

  defp format_args(args) do
    args
    |> Enum.map(fn arg -> type_to_string(arg_type(arg)) end)
    |> Enum.join(", ")
  end

  defp arg_type(nil), do: :nil
  defp arg_type(arg) when is_number(arg), do: :number
  defp arg_type(arg) when is_bitstring(arg), do: :string
  defp arg_type(arg) when is_boolean(arg), do: :boolean
  defp arg_type({:tref, _}), do: :table
  defp arg_type({:erl_func, _}), do: :function
  defp arg_type({:funref, _, _}), do: :function
  defp arg_type(_arg) do
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
