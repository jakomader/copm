defmodule Copm.Repo.Migrations.RefreshTokens do
  use Ecto.Migration

  def change do
    create table(:refresh_tokens) do
      add :operator_id, references(:operators, on_delete: :delete_all), null: false
      add :token_hash, :string, null: false
      add :expires_at, :utc_datetime, null: false
      add :revoked_at, :utc_datetime
      add :replaced_with_id, references(:refresh_tokens, on_delete: :nilify_all)

      timestamps()
    end

    create index(:refresh_tokens, [:operator_id])
    create unique_index(:refresh_tokens, [:token_hash])
  end
end
