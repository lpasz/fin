defmodule Fin.GmailImportWorker do
  use Oban.Worker, queue: :job, max_attempts: 3
  alias Fin.{Repo, User, Email, LLM}

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"user_id" => user_id}}) do
    user = Repo.get(User, user_id)
    if user do
      import_gmail_emails(user)
    else
      {:error, "User not found"}
    end
  end

  def import_gmail_emails(user) do
    # Fetch up to 100 most recent Gmail messages
    case Fin.Gmail.list_messages(user.token, user.email, max_results: 100) do
      {:ok, messages} ->
        Enum.each(messages, fn %{"id" => message_id} ->
          case Fin.Gmail.get_message(user.token, message_id) do
            {:ok, message_data} ->
              payload = message_data["payload"]
              headers = payload["headers"]
              body = get_email_body(payload)
              sender = Enum.find(headers, fn h -> h["name"] == "From" end)["value"]
              recipient = Enum.find(headers, fn h -> h["name"] == "To" end)["value"]
              subject = Enum.find(headers, fn h -> h["name"] == "Subject" end)["value"]
              sent_at = List.keyfind(headers, "Date", 0)["value"] |> parse_email_date()

              email_params = %{
                message_id: message_data["id"],
                thread_id: message_data["threadId"],
                sender: sender,
                recipient: recipient,
                subject: subject,
                body: body,
                sent_at: sent_at,
                user_id: user.id
              }

              case Repo.insert(Email.changeset(%Email{}, email_params)) do
                {:ok, email} ->
                  # Generate embedding in the background
                  Task.start(fn ->
                    case LLM.generate_embedding("#{subject} #{body}") do
                      {:ok, embedding} ->
                        Email.changeset(email, %{embedding: embedding}) |> Repo.update()
                      _ -> :noop
                    end
                  end)
                {:error, _} -> :noop
              end
            _ -> :noop
          end
        end)
        :ok
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp get_email_body(payload) do
    if payload["parts"] do
      # Join all text/plain and text/html parts, separated by newlines, skipping blanks
      payload["parts"]
      |> Enum.filter(fn p -> p["mimeType"] in ["text/plain", "text/html"] end)
      |> Enum.map(fn part ->
        if part["body"] && part["body"]["data"] do
          part["body"]["data"] |> Base.url_decode64!() |> String.trim()
        else
          ""
        end
      end)
      |> Enum.reject(&(&1 == ""))
      |> Enum.join("\n\n")
    else
      if payload["body"] && payload["body"]["data"] do
        payload["body"]["data"] |> Base.url_decode64!() |> String.trim()
      else
        ""
      end
    end
  end

  defp parse_email_date(date_string) do
    case Timex.parse(date_string, "{RFC1123}") do
      {:ok, datetime} -> datetime
      _ -> DateTime.utc_now()
    end
  end
end
