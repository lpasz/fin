defmodule FinWeb.AuthController do
  use FinWeb, :controller

  plug Ueberauth

  alias Fin.User
  alias Fin.Repo

  def callback(%{assigns: %{ueberauth_failure: _fails}} = conn, _params) do
    conn
    |> put_flash(:error, "Failed to authenticate.")
    |> redirect(to: "/")
  end

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    case find_or_create_user(auth) do
      {:ok, user} ->
        {:ok, _} =
          %{"user_id" => user.id}
          |> Fin.GmailImportList.new()
          |> Oban.insert()

        conn
        |> put_session(:user_id, user.id)
        |> put_flash(:info, "Logged in successfully.")
        |> redirect(to: "/chat")

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Failed to save user.")
        |> redirect(to: "/")
    end
  end

  def delete(conn, _params) do
    conn
    |> clear_session()
    |> put_flash(:info, "Logged out successfully.")
    |> redirect(to: "/")
  end

  defp find_or_create_user(auth) do
    user_params = %{
      email: auth.info.email,
      provider: to_string(auth.provider),
      token: auth.credentials.token,
      refresh_token: auth.credentials.refresh_token,
      expires_at: auth.credentials.expires_at,
      uid: auth.uid
    }

    case Repo.get_by(User, uid: auth.uid, provider: to_string(auth.provider)) do
      nil ->
        %User{}
        |> User.changeset(user_params)
        |> Repo.insert()

      user ->
        user
        |> User.changeset(user_params)
        |> Repo.update()
    end
  end
end
