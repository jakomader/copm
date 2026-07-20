defmodule Copm.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :user_id, :string, primary_key: true
      add :client_id, :string, null: false
      add :login, :string, null: false
      add :person, :map, null: false
      add :user_starts_at, :string, null: false
      add :user_ends_at, :string
      add :org_id, references(:organizations), null: false, primary_key: true

      timestamps()
    end

    create index(:users, [:client_id])
    create unique_index(:users, [:org_id, :login])
    create index(:users, [:org_id])


  end
end
