defmodule FinWeb.ChatMessageComponent do
  use FinWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class={
      case @message.role do
        :user -> "text-right"
        :bot -> "text-left"
      end
    }>
      <div class={
        case @message.role do
          :user -> "inline-block bg-blue-500 text-white p-2 rounded-lg"
          :bot -> "inline-block bg-gray-200 text-gray-800 p-2 rounded-lg chat-markdown"
        end
      }>
        <%= if @message.role == :bot do %>
          <%= raw(Earmark.as_html!(@message.content)) %>
        <% else %>
          <%= @message.content %>
        <% end %>
      </div>
    </div>
    """
  end
end
