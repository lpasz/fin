defmodule Fin.GmailImportOne do
  use Oban.Worker
  alias Fin.{Repo, User, Email, LLM}

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{"user_id" => user_id, "message_id" => message_id, "access_token" => access_token}
      }) do
    with {:ok, message_data} <- Fin.Gmail.get_message(access_token, message_id),
         payload = message_data["payload"],
         headers = payload["headers"],
         body = get_email_body(payload) |> String.slice(0, 15_000),
         sender = Enum.find(headers, fn h -> h["name"] == "From" end)["value"],
         recipient = Enum.find(headers, fn h -> h["name"] == "To" end)["value"],
         subject = Enum.find(headers, fn h -> h["name"] == "Subject" end)["value"],
         sent_at = List.keyfind(headers, "Date", 0)["value"] |> parse_email_date(),
         {:ok, embedding_values} <- LLM.generate_embedding("#{subject} #{body}") do
      email_params = %{
        message_id: message_data["id"],
        thread_id: message_data["threadId"],
        sender: sender,
        recipient: recipient,
        subject: subject,
        body: body,
        sent_at: sent_at,
        user_id: user_id,
        embedding: Pgvector.new(embedding_values)
      }

      changeset = Email.changeset_with_embedding(%Email{}, email_params)

      Repo.insert(
        changeset,
        on_conflict: [
          set: [embedding: email_params.embedding, updated_at: NaiveDateTime.utc_now()]
        ],
        conflict_target: :message_id,
        returning: true
      )
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
