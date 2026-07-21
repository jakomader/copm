defmodule CopmWeb.BatchController do
  use CopmWeb, :controller
  use OpenApiSpex.ControllerSpecs

  import Ecto.Query
  alias Copm.Repo
  alias CopmWeb.Schemas.{BatchProcessingResponse, BatchDeliveredResponse, BatchErrorResponse, ErrorResponse}

  tags(["ingest"])

  security([%{"bearerAuth" => []}])

  operation(:show_batch,
    summary: "Проверка статуса пакетной загрузки (транзакции) по batchId",
    description: """
    Каждый вызов `POST /api/ingest/:topic` или `POST /api/ingest/csv` возвращает `batchId` - идентификатор конкретной отправки (одна отправка = один батч, даже если в ней всего одна запись). По этому `batchId` можно проверить реальный статус обработки - то, что записи реально дошли до итогового хранилища, а не просто были приняты и поставлены в очередь Kafka.

    Возможные состояния ответа:
    * **`processing`** (`200`) - батч ещё обрабатывается, не все записи дошли до итогового хранилища (см. `total` / `processed`).
    * **`Доставлено`** (`202`) - все записи батча успешно обработаны, ошибок нет.
    * **ошибки присутствуют** (`400`) - хотя бы одна запись батча не прошла обработку (отсутствующий ключ, невалидное значение поля, неожиданное поле при актуализации и т.п.). Возвращается список ошибок с бизнес-ключом проблемной записи (или `item #N` - порядковым номером в пакете, если ключа не было вовсе) и текстом ошибки.
    """,
    parameters: [
      id: [
        in: :path,
        description: "batchId, полученный в ответе на POST /api/ingest/:topic или /api/ingest/csv",
        type: :string,
        example: "8c3001a5-f9cf-4838-98ca-590dd129aec0",
        required: true
      ]
    ],
    responses: [
      ok: {"Батч ещё обрабатывается", "application/json", BatchProcessingResponse},
      accepted: {"Батч полностью обработан, ошибок нет", "application/json", BatchDeliveredResponse},
      bad_request: {"Батч обработан (полностью или частично) с ошибками по отдельным записям", "application/json", BatchErrorResponse},
      not_found: {"Батч с таким id не найден (или принадлежит другой организации)", "application/json", ErrorResponse},
      unauthorized: {"Токен авторизации отсутствует, недействителен или роль не data_provider", "application/json", ErrorResponse}
    ]
  )

  def show_batch(conn, %{"id" => batch_id}) do
    org_id = conn.assigns.current_operator.org_id
    case Repo.get_by(Copm.Schemas.IngestBatches, org_id: org_id, batch_id: batch_id) do
      nil -> conn |> put_status(:not_found) |> json(%{error: "batch not found"})
      batch ->
        errors = Repo.all(from e in Copm.Schemas.IngestBatchErrors, where: e.batch_id == ^batch_id)
        if errors == [] do
          if batch.processed - batch.total == 0 do
            conn |> put_status(:accepted) |> json(%{status: "Все загружено, ошибок нет"})
          else
            conn |> json(%{status: "processing", total: batch.total, processed: batch.processed})
          end
        else
          if batch.processed - batch.total == 0 do
            conn |> put_status(:bad_request) |> json(%{status: "Ошибки присутствуют", error: Enum.map(errors, &%{businessKey: &1.business_key, message: &1.message})})
          else
            conn |> put_status(:bad_request) |> json(%{status: "Ошибки присутствуют, не все данные обработаны", error: Enum.map(errors, &%{businessKey: &1.business_key, message: &1.message})})
          end
        end

    end
  end
end
