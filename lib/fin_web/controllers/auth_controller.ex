
defmodule FinWeb.AuthController do
  use FinWeb, :controller
  plug Ueberauth

  def callback(%{assigns: %{ueberauth_failure: _fails}} = conn, _params) do
    conn
    |> put_flash(:error, "Failed to authenticate.")
    |> redirect(to: "/")
  end

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    IO.inspect(auth) # For now, just inspect the auth data
    conn
    |> put_flash(:info, "Logged in successfully.")
    |> redirect(to: "/")
  end

  def delete(conn, _params) do
    conn
    |> clear_session()
    |> put_flash(:info, "Logged out successfully.")
    |> redirect(to: "/")
  end
end
