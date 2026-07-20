defmodule Copm.Repo.Migrations.CreateClientRelation do
  use Ecto.Migration

  def change do
    create table(:client_relations) do
      add :client_id, :string, null: false
      add :full_name, :string, null: false
      add :inn, :string, null: false
      add :position, :string, null: false
      add :role, :string, null: false
      add :date_begin, :string
      add :date_end, :string
      add :org_id, references(:organizations), null: false

      timestamps()
    end

    create index(:client_relations, [:client_id])
    create index(:client_relations, [:inn])
    create index(:client_relations, [:org_id])

    execute(
      "ALTER TABLE client_relations ADD CONSTRAINT client_relations_org_client_fkey FOREIGN KEY (org_id, client_id) REFERENCES clients (org_id, client_id) ON DELETE CASCADE",
      "ALTER TABLE client_relations DROP CONSTRAINT client_relations_org_client_fkey"
    )
  end
end
