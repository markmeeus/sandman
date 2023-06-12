defmodule SandmanWeb.LiveView.Log do
  # In Phoenix v1.6+ apps, the line is typically: use MyAppWeb, :live_view
  use Phoenix.Component

  alias Sandman.Document
  alias Phoenix.PubSub

  @spec render(any) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
      <div id="sandman-log" class="text-black text-xs">
        <div id="log-bar" class="space-x-1 flex flex-row-reverse" style="background-color:#EEE">
          <button class="mr-1" >clear</button>
          <div class="grow">Log</div>
        </div>
        <div id="log-wrapper" class="font-mono p-2">
          <%= @log %>
        </div>
      </div>
    """
  end

  # def mount(_params, _session, socket) do
  #   # start_doc
  #   doc_id = UUID.uuid4()
  #   #PubSub.subscribe(Sandman.PubSub, "document:#{doc_id}")
  #   {:ok, doc_pid} = Document.start_link(doc_id, "/Users/markmeeus/Documents/projects/github/sandman/doc/test.json")

  #   socket = socket
  #   |> assign(:doc_pid, doc_pid)
  #   |> assign(:log, "")
  #   {:ok, socket}
  # end


end
