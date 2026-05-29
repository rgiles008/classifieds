defmodule Sunstate.Repo do
  use Ecto.Repo,
    otp_app: :sunstate,
    adapter: Ecto.Adapters.Postgres
end
