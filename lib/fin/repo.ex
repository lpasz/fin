defmodule Fin.Repo do
  use Ecto.Repo,
    otp_app: :fin,
    adapter: Ecto.Adapters.Postgres
end
