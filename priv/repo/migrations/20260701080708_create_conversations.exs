defmodule Copm.Repo.Migrations.CreateConversations do
  use Ecto.Migration

  def change do
    create table(:conversations, primary_key: false) do
      add :conversation_id, :string, primary_key: true
      add :client_id, :string, null: false
      add :user_id, :string, null: false
      add :session_id, :string, null: false
      add :starts_at, :utc_datetime, null: false
      add :ends_at, :utc_datetime
      add :channel, :string, null: false
      add :org_id, references(:organizations), null: false, primary_key: true
      timestamps()
    end

    create index(:conversations, [:client_id])
    create index(:conversations, [:user_id])
    create index(:conversations, [:session_id])
    create index(:conversations, [:org_id])

    execute(
      "ALTER TABLE conversations ADD CONSTRAINT conversations_org_client_fkey FOREIGN KEY (org_id, client_id) REFERENCES clients (org_id, client_id) ON DELETE RESTRICT",
      "ALTER TABLE conversations DROP CONSTRAINT conversations_org_client_fkey"
    )

    execute(
      "ALTER TABLE conversations ADD CONSTRAINT conversations_org_user_fkey FOREIGN KEY (org_id, user_id) REFERENCES users (org_id, user_id) ON DELETE RESTRICT",
      "ALTER TABLE conversations DROP CONSTRAINT conversations_org_user_fkey"
    )
  end
end
