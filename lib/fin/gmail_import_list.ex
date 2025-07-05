defmodule Fin.GmailImportList do
  use Oban.Worker
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
        messages
        |> Enum.map(fn %{"id" => message_id} ->
          Fin.GmailImportOne.new(%{
            "user_id" => user.id,
            "message_id" => message_id,
            "access_token" => user.token
          })
        end)
        |> Oban.insert_all()

      {:error, reason} ->
        {:error, reason}
    end
  end
end
