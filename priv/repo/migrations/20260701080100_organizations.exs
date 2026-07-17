defmodule Copm.Repo.Migrations.Organizations do
  use Ecto.Migration

  def change do
    create table(:organizations) do
      add :org_name, :string, null: false

      timestamps()
    end

    create unique_index(:organizations, [:org_name])
  end
end
