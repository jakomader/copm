defmodule Copm.Schemas.IngestBatchErrors do
  use Ecto.Schema
  import Ecto.Changeset

  schema "ingest_batch_errors" do
    belongs_to :ingest_batches, Copm.Schemas.IngestBatches, foreign_key: :batch_id, references: :batch_id, type: :binary_id
    field :business_key, :string
    field :message, :string

    timestamps(updated_at: false)
  end
  def changeset(batch, attrs) do
    batch
    |> cast(attrs, [:batch_id, :business_key, :message])
    |> validate_required([:batch_id, :business_key, :message])
  end
end
