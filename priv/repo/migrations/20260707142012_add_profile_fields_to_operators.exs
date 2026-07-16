defmodule Copm.Repo.Migrations.AddProfileFieldsToOperators do
  use Ecto.Migration

  def change do
    alter table(:operators) do
      add :name, :string, null: false, default: ""
      add :purpose, :string
      add :status, :string, null: false, default: "active"
    end

    create index(:operators, [:status])
  end
end
