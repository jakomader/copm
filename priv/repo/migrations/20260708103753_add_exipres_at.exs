defmodule Copm.Repo.Migrations.AddExipresAt do
  use Ecto.Migration

  def change do
    alter table(:api_tokens) do
      add :expires_at, :utc_datetime, null: false
    end
  end
end
