defmodule Copm.Repo do
  use Ecto.Repo,
    otp_app: :copm,
    adapter: Ecto.Adapters.Postgres
end
