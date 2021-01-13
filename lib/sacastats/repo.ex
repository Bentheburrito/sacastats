defmodule SacaStats.Repo do
  use Ecto.Repo,
    otp_app: :sacastats,
    adapter: Ecto.Adapters.Postgres
end
