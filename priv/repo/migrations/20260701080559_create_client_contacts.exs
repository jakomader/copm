defmodule Copm.Repo.Migrations.CreateClientContacts do
  use Ecto.Migration

  def change do
    create table(:client_contacts) do
      add :client_id, references(:clients, column: :client_id, type: :string, on_delete: :delete_all), null: false
      add :phone, :string, null: false
      add :email, :string, null: false

      timestamps()
    end
    create index(:client_contacts, [:client_id])
  end

end
