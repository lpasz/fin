defmodule Fin.Email do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Fin.Repo

  schema "emails" do
    field :message_id, :string
    field :thread_id, :string
    field :sender, :string
    field :recipient, :string
    field :subject, :string
    field :body, :string
    field :sent_at, :utc_datetime
    field :received_at, :utc_datetime, default: DateTime.truncate(DateTime.utc_now(), :second)
    field :embedding, Pgvector.Ecto.Vector

    belongs_to :user, Fin.User

    timestamps()
  end

  def changeset(email, attrs) do
    email
    |> cast(attrs, [
      :message_id,
      :thread_id,
      :sender,
      :recipient,
      :subject,
      :body,
      :sent_at,
      :received_at,
      :user_id
    ])
    |> validate_required([
      :message_id,
      :thread_id,
      :sender,
      :recipient,
      :subject,
      :body,
      :sent_at,
      :user_id
    ])
    |> unique_constraint(:message_id)
  end

  def changeset_with_embedding(email, attrs) do
    email
    |> cast(attrs, [
      :message_id,
      :thread_id,
      :sender,
      :recipient,
      :subject,
      :body,
      :sent_at,
      :received_at,
      :user_id,
      :embedding
    ])
    |> validate_required([
      :message_id,
      :thread_id,
      :sender,
      :recipient,
      :subject,
      :body,
      :sent_at,
      :user_id
    ])
    |> unique_constraint(:message_id)
  end

  @doc """
  Find similar emails using vector similarity search
  """
  def find_similar_emails(user_id, query_text) do
    case Fin.LLM.generate_embedding(query_text) do
      {:ok, query_embedding} ->
        # Use pgvector's cosine distance for similarity search
        from(e in __MODULE__,
          where: e.user_id == ^user_id and not is_nil(e.embedding),
          order_by: fragment("? <-> ?", e.embedding, ^Pgvector.new(query_embedding)),
        )
        |> Repo.all()
      
      {:error, _reason} ->
        # Fallback to recent emails if embedding generation fails
        get_recent_emails(user_id)
    end
  end

  @doc """
  Get recent emails as fallback when vector search fails
  """
  def get_recent_emails(user_id) do
    from(e in __MODULE__,
      where: e.user_id == ^user_id,
      order_by: [desc: e.sent_at],
    )
    |> Repo.all()
  end

  @doc """
  Generate and store embedding for an email
  """
  def generate_embedding(email) do
    # Combine subject and body for embedding
    text_content = "#{email.subject} #{email.body}" |> String.slice(0, 15_000)
    
    case Fin.LLM.generate_embedding(text_content) do
      {:ok, embedding_values} ->
        email
        |> changeset_with_embedding(%{embedding: Pgvector.new(embedding_values)})
        |> Repo.update()
      
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Count emails with embeddings for a user
  """
  def count_emails_with_embeddings(user_id) do
    from(e in __MODULE__,
      where: e.user_id == ^user_id and not is_nil(e.embedding)
    )
    |> Repo.aggregate(:count)
  end

  @doc """
  Generate embeddings for emails that don't have them yet
  """
  def generate_missing_embeddings(user_id) do
    emails_without_embeddings = 
      from(e in __MODULE__,
        where: e.user_id == ^user_id and is_nil(e.embedding)
      )
      |> Repo.all()

    total_count = length(emails_without_embeddings)
    IO.puts("Found #{total_count} emails without embeddings")

    emails_without_embeddings
    |> Enum.with_index(1)
    |> Enum.each(fn {email, index} ->
      IO.puts("Processing email #{index}/#{total_count}: #{email.subject}")
      
      case generate_embedding(email) do
        {:ok, _updated_email} ->
          IO.puts("✓ Generated embedding for email #{index}")
        {:error, reason} ->
          IO.puts("✗ Failed to generate embedding for email #{index}: #{inspect(reason)}")
      end
    end)
  end
end
