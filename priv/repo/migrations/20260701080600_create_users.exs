defmodule Copm.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :user_id, :string, primary_key: true
      add :client_id, references(:clients, column: :client_id, type: :string, on_delete: :restrict), null: false
      add :login, :string, null: false
      add :person, :map, null: false
      add :user_starts_at, :utc_datetime, null: false
      add :user_ends_at, :utc_datetime

      timestamps()
    end

    create index(:users, [:client_id])
    create unique_index(:users, [:login])
  end
end
