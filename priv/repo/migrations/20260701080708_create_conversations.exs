defmodule Copm.Repo.Migrations.CreateConversations do
  use Ecto.Migration

  def change do
    create table(:conversations, primary_key: false) do
      add :conversation_id, :string, primary_key: true
      add :client_id, :string, null: false
      add :user_id, :string, null: false
      add :session_id, :string, null: false
      add :starts_at, :string, null: false
      add :ends_at, :string
      add :channel, :string, null: false
      add :org_id, references(:organizations), null: false, primary_key: true
      timestamps()
    end

    create index(:conversations, [:client_id])
    create index(:conversations, [:user_id])
    create index(:conversations, [:session_id])
    create index(:conversations, [:org_id])

  end
end
