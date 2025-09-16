defmodule Sandman.DocumentHandlers do
  alias Sandman.HttpClient
  alias Sandman.LuerlWrapper

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
      {:get, &fetch_handler.(["GET"] ++ &1, &2), ["sandman", "http", "get"]},
      {:post, &fetch_handler.(["POST"] ++ &1, &2), ["sandman", "http", "post"]},
      {:put, &fetch_handler.(["PUT"] ++ &1, &2), ["sandman", "http", "put"]},
      {:delete, &fetch_handler.(["DELETE"] ++ &1, &2), ["sandman", "http", "delete"]},
      {:patch, &fetch_handler.(["PATCH"] ++ &1, &2), ["sandman", "http", "patch"]},
      {:head, &fetch_handler.(["HEAD"] ++ &1, &2), ["sandman", "http", "head"]},
      {:send, &fetch_handler.(&1, &2), ["sandman", "http", "send"]},
      {:print, fn args, luerl_state ->
        decoded_args = :luerl.decode_list(args, luerl_state)
        {:ok, res} = GenServer.call(self_pid, {:handle_lua_call, :print, decoded_args})
        {res, luerl_state}
      end, ["print"]},

      {:start_server, fn port, luerl_state ->
        {:ok, res} = GenServer.call(self_pid, {:handle_lua_call, :start_server, port})
        {res, luerl_state}
      end, ["sandman", "server", "start"]},
      {:document_set, fn [key, val], luerl_state ->
        decoded_val = :luerl.decode(val, luerl_state)
        {:ok, res} = GenServer.call(self_pid, {:handle_lua_call, :document_set, [key, decoded_val]})
        {res, luerl_state}
      end, ["sandman", "document", "set"]},
      {:document_get, fn [key], luerl_state ->
        {:ok, decoded_res} = GenServer.call(self_pid, {:handle_lua_call, :document_get, [key]})
        {res, luerl_state} = :luerl.encode(decoded_res, luerl_state)
        {[res], luerl_state}
      end, ["sandman", "document", "get"]},
      {:get, &add_route_handler.(["GET"] ++ &1, &2), ["sandman", "server", "get"]},
      {:post, &add_route_handler.(["POST"] ++ &1, &2), ["sandman", "server", "post"]},
      {:put, &add_route_handler.(["PUT"] ++ &1, &2), ["sandman", "server", "put"]},
      {:delete, &add_route_handler.(["DELETE"] ++ &1, &2), ["sandman", "server", "delete"]},
      {:patch, &add_route_handler.(["PATCH"] ++ &1, &2), ["sandman", "server", "patch"]},
      {:head, &add_route_handler.(["HEAD"] ++ &1, &2), ["sandman", "server", "head"]},
      {:add_route, &add_route_handler.(&1, &2), ["sandman", "server", "add_route"]},
      {:json_decode, &Json.decode(doc_id, &1, &2), ["sandman", "json", "decode"]},
      {:json_encode, &Json.encode(doc_id, &1, &2), ["sandman", "json", "encode"]},
      {:base64_decode, &Base64.decode(doc_id, &1, &2), ["sandman", "base64", "decode"]},
      {:base64_encode, &Base64.encode(doc_id, &1, &2), ["sandman", "base64", "encode"]},
      {:base64_decode_url, &Base64.decode_url(doc_id, &1, &2), ["sandman", "base64", "decode_url"]},
      {:base64_encode_url, &Base64.encode_url(doc_id, &1, &2), ["sandman", "base64", "encode_url"]},
      {:jwt_sign, &Jwt.sign(doc_id, &1, &2), ["sandman", "jwt", "sign"]},
      {:jwt_verify, &Jwt.verify(doc_id, &1, &2), ["sandman", "jwt", "verify"]},
      {:uri_parse, &LuaSupport.Uri.parse(doc_id, &1, &2), ["sandman", "uri", "parse"]},
      {:uri_tostring, &LuaSupport.Uri.tostring(doc_id, &1, &2), ["sandman", "uri", "tostring"]},
      {:uri_encode, &LuaSupport.Uri.encode(doc_id, &1, &2), ["sandman", "uri", "encode"]},
      {:uri_decode, &LuaSupport.Uri.decode(doc_id, &1, &2), ["sandman", "uri", "decode"]},
      {:uri_encodeComponent, &LuaSupport.Uri.encodeComponent(doc_id, &1, &2), ["sandman", "uri", "encodeComponent"]},
      {:uri_decodeComponent, &LuaSupport.Uri.decodeComponent(doc_id, &1, &2), ["sandman", "uri", "decodeComponent"]},
     ] |> wrap_handlers()
  end

  defp wrap_handlers(handlers) do
    handlers |>
    Enum.map(
      fn
        {name, handler, path} ->
          wrapped_handler = fn args, luerl_state ->
            # TODO, luerl decode args and luerl_encode results
            # TODO, tables should be mapped to results
            try do
              handler.(args, luerl_state)
            rescue
              error ->
                full_function_name = Enum.join(path, ".")
                :luerl_lib.lua_error("Invalid arguments for #{full_function_name}", luerl_state)
            end
          end
          {name, wrapped_handler, path}
      end)
    #Enum.into(%{})
  end
end
