defmodule Copm.Repo.Migrations.CreateIpdrRecords do
  use Ecto.Migration

  def change do
    create table(:ipdr_records) do
      add :ts, :string, null: false
      add :source_ip, :string, null: false
      add :source_port, :integer, null: false
      add :destination_ip, :string, null: false
      add :destination_port, :integer, null: false
      add :protocol, :string, null: false
      add :flag, :string
      add :bytes_transferred, :bigint, null: false
      add :org_id, references(:organizations), null: false

      timestamps()
    end

    create index(:ipdr_records, [:ts])
    create index(:ipdr_records, [:source_ip])
    create index(:ipdr_records, [:org_id])
  end
end
