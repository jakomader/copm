defmodule Copm.Repo.Migrations.CreateClientRelation do
  use Ecto.Migration

  def change do
    create table(:client_relations) do
      add :client_id, references(:clients, column: :client_id, type: :string, on_delete: :delete_all), null: false
      add :full_name, :string, null: false
      add :inn, :string, null: false
      add :position, :string, null: false
      add :role, :string, null: false
      add :date_begin, :date
      add :date_end, :date

      timestamps()
    end

    create index(:client_relations, [:client_id])
    create index(:client_relations, [:inn])
  end
end
