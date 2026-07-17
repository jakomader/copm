defmodule Copm.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :user_id, :string, primary_key: true
      add :client_id, :string, null: false
      add :login, :string, null: false
      add :person, :map, null: false
      add :user_starts_at, :utc_datetime, null: false
      add :user_ends_at, :utc_datetime
      add :org_id, references(:organizations), null: false, primary_key: true

      timestamps()
    end

    create index(:users, [:client_id])
    create unique_index(:users, [:login])
    create index(:users, [:org_id])

    execute(
      "ALTER TABLE users ADD CONSTRAINT users_org_client_fkey FOREIGN KEY (org_id, client_id) REFERENCES clients (org_id, client_id) ON DELETE RESTRICT",
      "ALTER TABLE users DROP CONSTRAINT users_org_client_fkey"
    )
  end
end
