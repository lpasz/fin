defmodule Fin.User do
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

  alias Fin.Repo
  alias Fin.Gmail
  alias Fin.Email

  schema "users" do
    field :email, :string
    field :provider, :string
    field :token, :string
    field :refresh_token, :string
    field :expires_at, :integer
    field :uid, :string

    timestamps()
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :provider, :token, :refresh_token, :expires_at, :uid])
    |> validate_required([:email, :provider, :uid])
    |> unique_constraint(:uid, name: :users_uid_provider_index)
  end

  def fetch_and_store_emails(user) do
    case Gmail.list_messages(user.token, user.email) do
      {:ok, messages} ->
        Enum.each(messages, fn %{"id" => message_id} ->
          case Gmail.get_message(user.token, message_id) do
            {:ok, message_data} ->
              # Parse message_data and save to database
              # This is a simplified parsing, you might need more robust parsing for different email formats
              payload = message_data["payload"]
              headers = payload["headers"]
              body = get_email_body(payload)

              sender = List.keyfind(headers, "From", 0)["value"]
              recipient = List.keyfind(headers, "To", 0)["value"]
              subject = List.keyfind(headers, "Subject", 0)["value"]
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

              %Email{}
              |> Email.changeset(email_params)
              |> Repo.insert()

            {:error, reason} ->
              IO.inspect(reason, label: "Error fetching message #{message_id}")
          end
        end)

      {:error, reason} ->
        IO.inspect(reason, label: "Error listing messages")
    end
  end

  defp get_email_body(payload) do
    if payload["parts"] do
      # Prioritize text/plain or text/html
      part =
        Enum.find(payload["parts"], fn p -> p["mimeType"] == "text/plain" end) ||
          Enum.find(payload["parts"], fn p -> p["mimeType"] == "text/html" end)

      if part && part["body"] && part["body"]["data"] do
        part["body"]["data"]
        |> Base.url_decode64!()
      else
        ""
      end
    else
      if payload["body"] && payload["body"]["data"] do
        payload["body"]["data"]
        |> Base.url_decode64!()
      else
        ""
      end
    end
  end

  defp parse_email_date(date_string) do
    # This is a very basic date parser. Gmail dates can be complex.
    # Consider using a more robust library like `Timex` for production.
    case Timex.parse(date_string, "{RFC1123}") do
      {:ok, datetime} -> datetime
      # Fallback
      _ -> DateTime.utc_now()
    end
  end

  def get_last_n_emails(user, _n) do
    Repo.preload(user, :emails)
  end
end
