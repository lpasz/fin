defmodule Fin.Repo.Migrations.CreateEmailsTable do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS vector"

    create table(:emails) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :subject, :text
      add :body, :text
      add :embedding, :vector

      timestamps()
    end

    create index(:emails, [:user_id])
  end
end