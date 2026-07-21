defmodule Copm.Repo.Migrations.CreateIngestBatches do
  use Ecto.Migration

  def change do
    create table(:ingest_batches, primary_key: false) do
      add :batch_id, :uuid, primary_key: true
      add :org_id, references(:organizations), null: false
      add :topic, :string, null: false
      add :total, :integer, null: false, default: 0
      add :processed, :integer, default: 0
      timestamps(updated_at: false)
    end

    create index(:ingest_batches, [:org_id])
  end
end
