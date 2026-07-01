defmodule Copm.Repo.Migrations.CreateConversations do
  use Ecto.Migration

  def change do
    create table(:conversations, primary_key: false) do
      add :conversation_id, :string, primary_key: true
      add :client_id, references(:clients, column: :client_id, type: :string, on_delete: :restrict), null: false
      add :user_id, references(:users, column: :user_id, type: :string, on_delete: :restrict), null: false
      add :session_id, :string, null: false
      add :starts_at, :utc_datetime, null: false
      add :ends_at, :utc_datetime
      add :channel, :string, null: false
      timestamps()
    end

    create index(:conversations, [:client_id])
    create index(:conversations, [:user_id])
    create index(:conversations, [:session_id])
  end
end
