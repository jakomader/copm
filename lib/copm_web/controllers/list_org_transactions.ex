defmodule CopmWeb.ListOrgTransactions do
  use CopmWeb, :controller
  use OpenApiSpex.ControllerSpecs

  import Ecto.Query
  alias Copm.Repo
  alias Copm.Schemas.{IngestBatches, IngestBatchErrors}
  alias CopmWeb.Schemas.TransactionListResponse

  tags(["ingest"])

  security([%{"bearerAuth" => []}])

  operation(:show_transact,
    summary: "Список всех транзакций (пакетных загрузок) оператора",
    description:
      "Возвращает все батчи, когда-либо отправленные организацией текущего оператора через POST /api/ingest/:topic или /api/ingest/csv, от новых к старым, вместе с их статусом обработки.",
    responses: [
      ok: {"Список транзакций организации", "application/json", TransactionListResponse}
    ]
  )

  def show_transact(conn, _params) do
    org_id = conn.assigns.current_operator.org_id

    error_counts =
      from(e in IngestBatchErrors, group_by: e.batch_id, select: {e.batch_id, count(e.id)})
      |> Repo.all()
      |> Map.new()
    transactions =
      from(b in IngestBatches, where: b.org_id == ^org_id, order_by: [desc: b.inserted_at])
      |> Repo.all()
      |> Enum.map(fn batch ->
        %{
          batchId: batch.batch_id,
          topic: batch.topic,
          total: batch.total,
          processed: batch.processed,
          status: status(batch, Map.get(error_counts, batch.batch_id, 0)),
          insertedAt: batch.inserted_at
        }
      end)

    conn |> json(%{transactions: transactions})
  end

  defp status(batch, error_count) do
    cond do
      error_count > 0 and batch.processed - batch.total == 0 -> "Ошибки присутствуют"
      error_count > 0 -> "Ошибки присутствуют, не все данные обработаны"
      batch.processed - batch.total == 0 -> "Доставлено"
      true -> "processing"
    end
  end
end
