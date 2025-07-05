defmodule Mix.Tasks.GenerateEmbeddings do
  @moduledoc """
  Generate embeddings for emails that don't have them yet.

  ## Usage

      mix generate_embeddings
      mix generate_embeddings --user-id 1

  """
  use Mix.Task

  alias Fin.Repo
  alias Fin.User
  alias Fin.Email

  @shortdoc "Generate embeddings for emails"

  def run(args) do
    Mix.Task.run("app.start")

    {parsed, _, _} = OptionParser.parse(args, switches: [user_id: :integer])

    case parsed[:user_id] do
      nil ->
        # Generate embeddings for all users
        generate_embeddings_for_all_users()

      user_id ->
        # Generate embeddings for specific user
        generate_embeddings_for_user(user_id)
    end
  end

  defp generate_embeddings_for_all_users do
    users = Repo.all(User)

    IO.puts("Generating embeddings for #{length(users)} users...")

    Enum.each(users, fn user ->
      IO.puts("Processing user: #{user.email}")
      Email.generate_missing_embeddings(user.id)
    end)

    IO.puts("Done!")
  end

  defp generate_embeddings_for_user(user_id) do
    case Repo.get(User, user_id) do
      nil ->
        IO.puts("User with ID #{user_id} not found")

      user ->
        IO.puts("Processing user: #{user.email}")
        Email.generate_missing_embeddings(user.id)
        IO.puts("Done!")
    end
  end
end
