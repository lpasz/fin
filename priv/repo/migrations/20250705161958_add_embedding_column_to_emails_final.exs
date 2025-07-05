defmodule Fin.Repo.Migrations.AddEmbeddingColumnToEmailsFinal do
  use Ecto.Migration

  def change do
    alter table(:emails) do
      add :embedding, :vector, size: 1536
    end
  end
end
