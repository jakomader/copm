defmodule Copm.Repo.Migrations.CreateAuthEvents do
  use Ecto.Migration

  def change do
    create table(:auth_events) do
      add :user_id, references(:users, column: :user_id, type: :string, on_delete: :restrict), null: false
      add :session_id, :string, null: false
      add :session_ts, :utc_datetime, null: false
      add :event_type, :string, null: false
      add :ip_address, :map, null: false
      add :user_agent, :string, null: false
      add :device_id, :string
      add :geolocation, :string

      timestamps()
    end

    create index(:auth_events, [:user_id])
    create index(:auth_events, [:session_id])
    create index(:auth_events, [:session_ts])
  end
end
