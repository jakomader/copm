defmodule Copm.Repo.Migrations.CreateApiTokens do
  use Ecto.Migration

  def change do
    create table(:api_tokens) do
      add :operator_id, references(:operators, on_delete: :delete_all), null: false
      add :token_hash, :string, null: false
      add :revoked_at, :utc_datetime

      timestamps()
    end

    create index(:api_tokens, [:operator_id])
    create unique_index(:api_tokens, [:token_hash])
  end
end
