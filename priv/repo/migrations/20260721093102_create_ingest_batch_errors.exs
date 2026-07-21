defmodule Copm.Repo.Migrations.CreateIngestBatchErrors do
  use Ecto.Migration

  def change do
    create table(:ingest_batch_errors) do
      add :batch_id, references(:ingest_batches, column: :batch_id, type: :uuid, on_delete: :delete_all), null: false
      add :business_key, :string, null: false
      add :message, :text, null: false

      timestamps(updated_at: false)

    end

    create index(:ingest_batch_errors, [:batch_id])

  end
end
