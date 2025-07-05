defmodule Fin.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :email, :string, null: false
      add :provider, :string, null: false
      add :token, :text
      add :refresh_token, :text
      add :expires_at, :bigint
      add :uid, :string

      timestamps()
    end

    create index(:users, [:email])
    create unique_index(:users, [:uid, :provider])
  end
end
