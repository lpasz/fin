defmodule FinWeb.ChatMessageComponent do
  use FinWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class={
      case @message.role do
        :user -> "flex justify-end"
        :bot -> "flex justify-start"
      end
    }>
      <div class={
        case @message.role do
          :user ->
            "max-w-xs lg:max-w-md bg-blue-600 text-white px-4 py-3 rounded-2xl rounded-br-md shadow-sm"

          :bot ->
            "max-w-2xl bg-white text-gray-900 px-4 py-3 rounded-2xl rounded-bl-md shadow-sm border border-gray-200 chat-markdown"
        end
      }>
        <%= if @message.role == :bot do %>
          {raw(Earmark.as_html!(@message.content))}
        <% else %>
          {@message.content}
        <% end %>
      </div>
    </div>
    """
  end
end
