defmodule FinWeb.ChatLive do
  use FinWeb, :live_view
  import Phoenix.HTML.Form
  import Phoenix.LiveView.Helpers

  alias Fin.User
  alias Fin.Repo
  alias Fin.LLM

  def mount(_params, %{"user_id" => user_id} = _session, socket) do
    {:ok,
     assign(socket,
       messages: [],
       user_input: "",
       user_id: user_id
     )}
  end

  def handle_event("send_message", %{"message" => message}, socket) do
    user = Fin.Repo.get(Fin.User, socket.assigns.user_id)
    last_10_emails = Fin.User.get_last_n_emails(user, 10)

    user_message = %{role: :user, content: message}
    bot_response = %{role: :bot, content: generate_response(message, last_10_emails)}

    messages = socket.assigns.messages ++ [user_message, bot_response]

    {:noreply,
     assign(socket,
       messages: messages,
       user_input: ""
     )}
  end

  defp generate_response(user_question, emails) do
    email_contents = Enum.map(emails, fn email ->
      "Subject: #{email.subject}\nBody: #{email.body}"
    end)
    |> Enum.join("\n\n")

    full_prompt = "You are an AI assistant that answers questions about emails.\n\nUser question: #{user_question}\n\nEmails:\n#{email_contents}"

    case Fin.LLM.generate_content(full_prompt) do
      {:ok, response_text} ->
        response_text
      {:error, reason} ->
        "Error generating response: #{inspect(reason)}"
    end
  end
end
