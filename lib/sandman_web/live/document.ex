defmodule SandmanWeb.LiveView.Document do
  # In Phoenix v1.6+ apps, the line is typically: use MyAppWeb, :live_view
  use Phoenix.Component

  alias Sandman.Document
  alias Phoenix.PubSub

  def mount(_params, _session, socket) do
    socket = assign(socket, :code, "some code")
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div phx-hook="DocumentHook" id="document">
      <h1 class="text-xl text-center mx-5 mt-1 font-bold" contenteditable="true">
        New Script
      </h1>
      <%= case @document["blocks"] do
        [] -> render_empty_state(assigns)
        _ -> render_blocks(assigns)
      end %>
    </div>
    """
  end

  def render_empty_state(assigns) do
    ~H"""
      <button class="pt-1 text-sm" phx-click="add-block" phx-value-block-id="-">Add Block</button>
    """
  end
  def render_blocks(assigns) do
    ~H"""
    <button class="pt-1 text-sm" phx-click="add-block" phx-value-block-id="-">Add block</button>
    <%= Enum.map(@document["blocks"], fn block ->%>
        <div class="my-1 pt-1 pb-5 px-5 border-b-2">
          <div class="flex flex-row fs-2 mb-1 text-sm">
          <button><span><%="▶"%></span> Run</button><button class="mx-2">
          <span><%="▶▶"%></span>From top</button></div>
          <div class="rounded-t p-2" style="background-color: rgb(30, 30, 30);">
            <div id={"monaco-#{block["id"]}"} phx-hook="MonacoHook" data-block-id={block["id"]} phx-update="ignore"><%= block["code"] %></div>
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
          <div class="flex flex-row">
            <button class="pt-1 text-sm" phx-click="add-block" phx-value-block-id={block["id"]}>Add</button>
            <div class="grow"/>
            <button class="pt-1 text-sm" phx-click="remove-block" phx-value-block-id={block["id"]}>Remove</button>
          </div>
        </div>
      <% end) %>
    """
  end
end
