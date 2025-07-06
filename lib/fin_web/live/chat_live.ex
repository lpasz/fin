defmodule FinWeb.ChatLive do
  use FinWeb, :live_view

  alias FinWeb.ChatMessageComponent

  def mount(_params, %{"user_id" => user_id} = _session, socket) do
    {:ok,
     assign(socket,
       messages: [],
       user_input: "",
       user_id: user_id
     )}
  end

  def handle_event("user_input", %{"message" => message}, socket) do
    {:noreply, assign(socket, user_input: message)}
  end

  def handle_event("send_message", %{"message" => message}, socket) do
    user_id = socket.assigns.user_id
    similar_emails = Fin.Email.find_similar_emails(user_id, message)

    user_message = %{role: :user, content: message}
    bot_response = %{role: :bot, content: generate_response(message, similar_emails)}

    messages = socket.assigns.messages ++ [user_message, bot_response]

    {:noreply,
     assign(socket,
       messages: messages,
       user_input: ""
     )}
  end

  defp generate_response(user_question, emails) do
    email_contents =
      Enum.map(emails, fn email ->
        "Subject: #{email.subject}\nBody: #{email.body}"
      end)
      |> Enum.join("\n\n")

    full_prompt =
      "You are an AI assistant that answers questions about emails.\n\nUser question: #{user_question}\n\nEmails:\n#{email_contents}"

    case Fin.LLM.generate_content(full_prompt) do
      {:ok, response_text} ->
        response_text

      {:error, reason} ->
        "Error generating response: #{inspect(reason)}"
    end
  end
end
