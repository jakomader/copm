defmodule Copm.Repo.Migrations.CreateClients do
  use Ecto.Migration

  def change do
    create table(:clients, primary_key: false) do
      add :client_id, :string, primary_key: true
      add :client_status, :string, null: false
      add :registration_date, :string, null: false
      add :full_name, :string, null: false
      add :short_name, :string
      add :inn, :string, null: false
      add :kpp, :string
      add :ogrn, :string, null: false
      add :okpo, :string
      add :tax_agency_code, :string
      add :legal_address, :map, null: false
      add :postal_address, :map
      add :reg_country_code, :string, null: false
      add :is_foreign, :boolean, null: false, default: false
      add :economic_sector, :string
      add :bank_info, :map, null: false
      add :org_id, references(:organizations), null: false, primary_key: true

      timestamps()
    end

    create index(:clients, [:inn])
    create index(:clients, [:ogrn])
    create index(:clients, [:org_id])
  end
end
