defmodule FinWeb.ChatLive do
  use FinWeb, :live_view

  alias FinWeb.ChatMessageComponent

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       messages: [],
       user_input: ""
     )}
  end

  def handle_event("send_message", %{"message" => message}, socket) do
    user_message = %{role: :user, content: message}
    bot_response = %{role: :bot, content: generate_response(message)}

    messages = socket.assigns.messages ++ [user_message, bot_response]

    {:noreply,
     assign(socket,
       messages: messages,
       user_input: ""
     )}
  end

  def handle_event("update_input", %{"message" => value}, socket) do
    {:noreply, assign(socket, user_input: value)}
  end

  defp generate_response(_message) do
    # replace this with your AI call
    "This is a dummy response."
  end
end
