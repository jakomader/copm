defmodule Copm.IngestBatches do
  import Ecto.Query
  alias Copm.Repo
  alias Copm.Schemas.{IngestBatchErrors, IngestBatches}

  def start_batch(org_id, topic, total) do
    batch_id = Ecto.UUID.generate()

    %IngestBatches{}
    |> IngestBatches.changeset(%{batch_id: batch_id, org_id: org_id, topic: topic, total: total})
    |> Repo.insert()
    |> case do
      {:ok, _batch} -> {:ok, batch_id}
      {:error, changeset} -> {:error, changeset}
    end
  end

  def mark_processed(batch_id, business_key, error \\ nil)

  def mark_processed(batch_id, _business_key, nil) do
    from(b in IngestBatches, where: b.batch_id == ^batch_id)
    |> Repo.update_all(inc: [processed: 1])

    :ok
  end

  def mark_processed(batch_id, business_key, error) do
    from(b in IngestBatches, where: b.batch_id == ^batch_id)
    |> Repo.update_all(inc: [processed: 1])

    %IngestBatchErrors{}
    |> IngestBatchErrors.changeset(%{batch_id: batch_id, business_key: business_key, message: error})
    |> Repo.insert!()

    :ok
  end
end
