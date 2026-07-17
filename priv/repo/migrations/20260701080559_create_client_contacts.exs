defmodule Copm.Repo.Migrations.CreateClientContacts do
  use Ecto.Migration

  def change do
    create table(:client_contacts) do
      add :client_id, :string, null: false
      add :phone, :string, null: false
      add :email, :string, null: false
      add :org_id, references(:organizations), null: false

      timestamps()
    end
    create index(:client_contacts, [:client_id])
    create index(:client_contacts, [:org_id])

    execute(
      "ALTER TABLE client_contacts ADD CONSTRAINT client_contacts_org_client_fkey FOREIGN KEY (org_id, client_id) REFERENCES clients (org_id, client_id) ON DELETE CASCADE",
      "ALTER TABLE client_contacts DROP CONSTRAINT client_contacts_org_client_fkey"
    )
  end

end
