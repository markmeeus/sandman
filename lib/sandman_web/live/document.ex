defmodule SandmanWeb.LiveView.Document do
  # In Phoenix v1.6+ apps, the line is typically: use MyAppWeb, :live_view
  use Phoenix.LiveView,
    container: {:div, class: "h-full"}

  alias Sandman.Document
  alias Phoenix.PubSub

  @spec render(any) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <h1 class="text-xl text-center mx-5 mt-1 font-bold" contenteditable="true">
      New Script
    </h1>

    <div class="flex rounded my-1 py-2 px-5 border-b-2">
      <h1>My First Request.</h1>
    </div>
    <div class="my-1 pt-1 pb-5 px-5 border-b-2">
      <div class="flex flex-row fs-2 mb-1 text-sm">
      <button><span><%="▶"%></span> Run</button><button class="mx-2">
      <span><%="▶▶"%></span>From top</button></div>
      <div class="rounded-t p-2" style="background-color: rgb(30, 30, 30);">
        <div id="monaco-1" phx-hook="MonacoHook">
          <%="test code" %>
        </div>
      </div>
      <div class="flex flex-col">
       <div class="flex flex-row-reverse text-xs rounded-b pb-1 px-1" style="background-color: rgb(238, 238, 238);">
       <a href="#" class="mt-1 text-emerald-600">&nbsp;<%="2xx"%></a>
       <a href="#" class="mt-1">3 requests</a>
       </div>
       <div class="flex flex-row-reverse text-xs rounded-b pb-1 px-1" style="background-color: rgb(238, 238, 238);">
       <a href="#" class="mt-1 text-emerald-600">&nbsp;302</a>
       <a href="#" class="mt-1">1 request</a></div>
       <div class="flex flex-row-reverse text-xs rounded-b pb-1 px-1" style="background-color: rgb(238, 238, 238);">
       <a href="#" class="mt-1 text-red-700">&nbsp;500</a>
       <a href="#" class="mt-1"><%= "GET https://test.com"%></a></div></div>
       </div>

       <button>New block</button>
    """
  end
end
