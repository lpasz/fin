defmodule Fin.Email do
  use Ecto.Schema
  import Ecto.Changeset

  schema "emails" do
    field :message_id, :string
    field :thread_id, :string
    field :sender, :string
    field :recipient, :string
    field :subject, :string
    field :body, :string
    field :sent_at, :utc_datetime
    field :received_at, :utc_datetime, default: DateTime.truncate(DateTime.utc_now(), :second)

    belongs_to :user, Fin.User

    timestamps()
  end

  def changeset(email, attrs) do
    email
    |> cast(attrs, [:message_id, :thread_id, :sender, :recipient, :subject, :body, :sent_at, :received_at, :user_id])
    |> validate_required([:message_id, :thread_id, :sender, :recipient, :subject, :body, :sent_at, :user_id])
    |> unique_constraint(:message_id)
  end
end
