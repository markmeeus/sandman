defmodule Sandman.LuerlWrapper do

  import Sandman.ErrorFormatter

  def init(handlers) do
    luerl_state = :luerl_sandbox.init()
    Enum.reduce(handlers, luerl_state, fn {path, handler}, luerl_state ->
      modules_path = Enum.drop(path, -1)
      {_, luerl_state} = Enum.reduce(modules_path, {[], luerl_state}, fn path, {path_list, luerl_state} ->
        path_list = path_list ++ [path]
        luerl_state = if(! lua_table_exists?(luerl_state, path_list)) do
          {:ok, luerl_state} = :luerl.set_table_keys_dec(path_list, [], luerl_state)
          luerl_state
        else
          luerl_state
        end
        {path_list, luerl_state}
      end)

      {:ok, luerl_state} = :luerl.set_table_keys_dec(path, handler, luerl_state)
      luerl_state
    end)
  end


  def set_context(luerl_state, context) do
    {:ok, luerl_state} = :luerl.set_table_keys_dec(["sandman", "_context"], [] , luerl_state)
    {:ok, luerl_state} =:luerl.set_table_keys_dec(["sandman", "_context", "block_id"], context.block_id , luerl_state)
    luerl_state
  end
  def get_context(luerl_state) do
    {:ok, block_id, _luerl_state} = :luerl.get_table_keys_dec(["sandman", "_context", "block_id"], luerl_state)
    %{
      block_id: block_id
    }
  end

  def collect_garbage(luerl_state) do
    :luerl.gc(luerl_state)
  end

  def decode(term, luerl_state) do
    :luerl.decode(term, luerl_state)
  end

  def run_code(code, luerl_state) do
    try do
      case :luerl.do(code, luerl_state) do
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
      {args, luerl_state} = :luerl.encode_list(args, luerl_state)
      case :luerl.call_function(
        func, args, luerl_state) do
        {:ok, res, luerl_state} ->
          # decode result
          res = :luerl.decode_list(res, luerl_state)
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

  def get_call_info(luerl_state) do
    line_nr = luerl_state
      |> :luerl.get_stacktrace()
      |> Enum.reduce(0, fn
        {_, _, [file: _, line: line_nr]}, _ -> line_nr
        _, last_line_nr -> last_line_nr
      end)

    %{block_id: block_id} = get_context(luerl_state)

    %{
      line_nr: line_nr,
      block_id: block_id
    }
  end

  defp lua_table_exists?(luerl_state, path) do
    case :luerl.get_table_keys_dec(path, luerl_state) do
      {:ok, nil, _} -> false
      {:ok, _, _} -> true
    end
  end

end


#[_, call_location={_, [], [file: _, line: line_nr]} | _] = [{"-no-name-", [], [file: "-no-file-", line: 8]}, {"test", [], [file: "-no-file-", line: 5]}, {{:luerl, :"-encode/2-fun-1-"}, ["https://sandmanapp.com"], [file: "luerl.erl"]}]
#[{"-no-name-", [], [file: "-no-file-", line: 8]}, {{:luerl, :"-encode/2-fun-1-"}, ["https://sandmanapp.com"], [file: "luerl.erl"]}]
