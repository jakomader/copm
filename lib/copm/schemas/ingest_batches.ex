defmodule Copm.Schemas.IngestBatches do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:batch_id, :binary_id, autogenerate: false}
  schema "ingest_batches" do
    belongs_to :organization, Copm.Schemas.Organizations, foreign_key: :org_id
    field :topic, :string
    field :total, :integer, default: 0
    field :processed, :integer, default: 0

    timestamps(updated_at: false)
  end
  def changeset(ingest_batch, attrs) do
    ingest_batch
    |> cast(attrs, [:org_id, :topic, :total, :processed, :batch_id])
    |> validate_required([:batch_id, :org_id, :topic, :total])
    |> foreign_key_constraint(:org_id)
  end
end
