defmodule Copm.Repo.Migrations.CreateApiTokens do
  use Ecto.Migration

  def change do
    create table(:api_tokens) do
      add :name, :string, null: false
      add :token_hash, :string, null: false
      add :revoked_at, :utc_datetime

      timestamps()
    end

    create unique_index(:api_tokens, [:token_hash])
  end
end
