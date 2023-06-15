defmodule Sandman.Logger do

  alias Phoenix.PubSub

  def log(doc_id, message) when  is_bitstring(message) do
    case Hammer.check_rate("log:#{doc_id}", 5000, 1000) do
      {:allow, 1000 } ->
          trimmed_message = limit(message)
          PubSub.broadcast(Sandman.PubSub, "document:#{doc_id}", {:log, %{
            type: "log",
            text: "Max log throughput (1000/5s) exceeded ... "
          }})
      {:allow, count } ->
        trimmed_message = limit(message)
        PubSub.broadcast(Sandman.PubSub, "document:#{doc_id}", {:log, %{
          type: "log",
          text: trimmed_message
        }})
      {:deny, _} -> nil
    end
  end
  def log(document_id, message) when is_list(message) do
    Enum.map(message, fn msg ->
      log(document_id, msg)
    end)
  end
  def log(document_id, message) when is_integer(document_id) do
    log(document_id, inspect(message))
  end

  def limit(printable) do
    if(String.length(printable) > 1024) do
      {lead, rest} = String.split_at(printable, 1000)
      {_middle, trail} = String.split_at(rest, -20)
      lead <> "..." <> trail
    else
      printable
    end
  end

end
