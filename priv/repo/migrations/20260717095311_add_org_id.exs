defmodule Copm.Repo.Migrations.AddOrgId do
  use Ecto.Migration

  def change do
    alter table(:operators) do
      add :org_id, references(:organizations), null: true
    end
    create index(:operators, [:org_id])
  end
end
