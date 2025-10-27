defmodule Sandman.LuaSupport.GetEnv do
  def getenv(doc_pid, _doc_id,  [key], luerl_state) do
    try do
      if String.starts_with?(key, "SANDMAN_") do
        value =GenServer.call(doc_pid, {:handle_lua_call, :getenv, key})
        {[value], luerl_state}
      else
        {:error, "Environment variable must be prefixed with SANDMAN_", luerl_state}
      end
    rescue
      error ->
        {:error, "Failed to get environment variable: #{error.message}", luerl_state}
    end
  end
end
