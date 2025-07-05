defmodule Fin.User do
  use Ecto.Schema
  import Ecto.Changeset

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
end
