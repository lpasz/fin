defmodule Fin.Repo.Migrations.UpdateEmbeddingDimension do
  use Ecto.Migration

  def up do
    # First, delete all existing embeddings to avoid conflicts
    execute("UPDATE emails SET embedding = NULL")

    # Then, alter the column to the correct dimension
    alter table(:emails) do
      modify :embedding, :vector, size: 768
    end
  end

  def down do
    # Revert to the old dimension if needed
    alter table(:emails) do
      modify :embedding, :vector, size: 1536
    end
  end
end