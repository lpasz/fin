defmodule Fin.Repo.Migrations.CreateEmailsTable do
  use Ecto.Migration

  def change do
    create table(:emails) do
      add :message_id, :string, null: false
      add :thread_id, :string, null: false
      add :sender, :string, null: false
      add :recipient, :string, null: false
      add :subject, :string, null: false
      add :body, :text, null: false
      add :sent_at, :utc_datetime, null: false
      add :received_at, :utc_datetime, null: false
      add :user_id, references(:users, on_delete: :nothing), null: false

      timestamps()
    end

    create unique_index(:emails, [:message_id])
  end
end
