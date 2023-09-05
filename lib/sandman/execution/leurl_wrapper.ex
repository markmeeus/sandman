defmodule Sandman.LuerlWrapper do

  import Sandman.ErrorFormatter

  def init(handlers) do
    luerl_state = :luerl_sandbox.init()
    #luerl_state = :luerl_new.set_trace_func(handlers.trace, luerl_state)
    luerl_state = :luerl.set_table(["print"], handlers.print, luerl_state)

    # not sure if I want to keep this ... sleeping on it
    # luerl_state = :luerl.set_table(["cron"], [], luerl_state)
    # {:ok, [], luerl_state} = :luerl_new.set_table_keys(["cron","start"], {:erl_func, handlers.cron_start}, luerl_state)
    # {:ok, [], luerl_state} = :luerl_new.set_table_keys(["cron","stop"], {:erl_func, handlers.cron_stop}, luerl_state)
    luerl_state = :luerl.set_table(["sandman"], [], luerl_state)

    luerl_state = :luerl.set_table(["sandman", "server"], [], luerl_state)
    luerl_state = :luerl.set_table(["sandman", "server", "start"], handlers.start_server, luerl_state)
    luerl_state = Enum.reduce(["GET", "POST", "PUT", "DELETE", "PATCH", "HEAD"], luerl_state, fn method, luerl_state ->
      {:ok, [], luerl_state} = :luerl_new.set_table_keys(["sandman", "server", String.downcase(method)],
        {:erl_func, &handlers.add_route.(method, &1, &2)}, luerl_state)
      luerl_state
    end)

    luerl_state = :luerl.set_table(["sandman", "http"], [], luerl_state)
    luerl_state = Enum.reduce(["get", "post", "put", "delete", "patch", "head"], luerl_state, fn method, luerl_state ->
      :luerl.set_table(["sandman", "http", String.downcase(method)], &handlers.fetch.(String.upcase(method), &1, &2), luerl_state)
    end)

    :luerl.set_table(["sandman", "http", "send"], fn args, luerl_state ->
      case args do
        [] -> handlers.fetch.(nil, [], luerl_state) # this is wrong, handlers will handle it
        [method] -> handlers.fetch.(method, [], luerl_state) # this is also wrong, handlers will handle it
        [method | args] -> handlers.fetch.(method, args, luerl_state) # this is also wrong, handlers will handle it
      end
    end, luerl_state)

    luerl_state = :luerl.set_table(["sandman", "uri"], [], luerl_state)
    luerl_state = :luerl.set_table(["sandman", "uri", "parse"], handlers.uri.parse, luerl_state)
    luerl_state = :luerl.set_table(["sandman", "uri", "tostring"], handlers.uri.tostring, luerl_state)
    luerl_state = :luerl.set_table(["sandman", "uri", "encode"], handlers.uri.encode, luerl_state)
    luerl_state = :luerl.set_table(["sandman", "uri", "decode"], handlers.uri.decode, luerl_state)
    luerl_state = :luerl.set_table(["sandman", "uri", "encodeComponent"], handlers.uri.encodeComponent, luerl_state)
    luerl_state = :luerl.set_table(["sandman", "uri", "decodeComponent"], handlers.uri.decodeComponent, luerl_state)

    luerl_state = :luerl.set_table(["sandman", "json"], [], luerl_state)
    luerl_state = :luerl.set_table(["sandman", "json", "encode"], handlers.json_encode, luerl_state)
    :luerl.set_table(["sandman", "json", "decode"], handlers.json_decode, luerl_state)

  end

  def collect_garbage(luerl_state) do
    :luerl_new.gc(luerl_state)
  end

  def decode(term, luerl_state) do
    :luerl_new.decode(term, luerl_state)
  end

  def run_code(code, luerl_state) do
    try do
      case :luerl_new.do(code, luerl_state) do
        {:ok, res, luerl_state} ->
          {:ok, res, luerl_state}

        {:error, error, luerl_state} ->
          {:error, error, luerl_state, format_parse_error(error)}
        {:lua_error, error, luerl_state} ->
          #lua error
          {:error, error, luerl_state, format_lua_error(error, luerl_state)}
      end
    rescue exception ->
      {:error, exception, luerl_state, format_exception(exception, luerl_state)}
    end
  end

  # # TODO: remove this, every call should be with a funref
  # def call_function(func, args, luerl_state) when is_bitstring(func) do
  #   function_keypath = String.split(func, ".")
  #   case :luerl_new.get_table_keys_dec(function_keypath, luerl_state) do
  #     {:ok, nil, _} ->
  #       {:error, :no_such_function_at_keypath, luerl_state,
  #         "Function #{func} does not exist."}
  #     _ ->
  #       call_existing_function(function_keypath, args, luerl_state)
  #    end
  # end
  def call_function(func, args, luerl_state) do
    try do
      {args, luerl_state} = :luerl_new.encode_list(args, luerl_state)
      case :luerl_new.call_function(
        func, args, luerl_state) do
        {:ok, res, luerl_state} ->
          # decode result
          res = :luerl_new.decode_list(res, luerl_state)
          {:ok, res, luerl_state}

        {:error, error, luerl_state} ->
          {:error, error, luerl_state, format_parse_error(error)}
        {:lua_error, error, luerl_state} ->
          #lua error
          {:error, error, luerl_state, format_lua_error(error, luerl_state)}
      end
    rescue exception ->
     {:error, exception, luerl_state, format_exception(exception, luerl_state)}
    end
  end
end
