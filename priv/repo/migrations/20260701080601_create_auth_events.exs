defmodule Copm.Repo.Migrations.CreateAuthEvents do
  use Ecto.Migration

  def change do
    create table(:auth_events) do
      add :user_id, :string, null: false
      add :session_id, :string, null: false
      add :session_ts, :string, null: false
      add :event_type, :string, null: false
      add :ip_address, :map, null: false
      add :user_agent, :string, null: false
      add :device_id, :string
      add :geolocation, :string
      add :org_id, references(:organizations), null: false

      timestamps()
    end

    create index(:auth_events, [:user_id])
    create index(:auth_events, [:session_id])
    create index(:auth_events, [:session_ts])
    create index(:auth_events, [:org_id])

  end
end
