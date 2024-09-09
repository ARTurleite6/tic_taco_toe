defmodule Ttc.Repo do
  use Ecto.Repo,
    otp_app: :ttc,
    adapter: Ecto.Adapters.Postgres
end
