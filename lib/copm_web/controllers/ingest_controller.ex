defmodule CopmWeb.IngestController do
  use CopmWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias Copm.CsvSwallower
  alias Copm.CsvSwallower.Producer
  alias CopmWeb.Schemas.{IngestAcceptedResponse, CsvIngestResponse, VerificationResponse, ErrorResponse}
  alias OpenApiSpex.Schema

  tags(["ingest"])

  security([%{"bearerAuth" => []}])

  operation(:create,
    summary: "Приём одной записи по конкретному топику",
    description:
      "Принимает JSON-объект с данными одной сущности (заказ, клиент, платёж и т.д.) и публикует его во внутренний Kafka-топик. Доступно только оператору с ролью data_provider.",
    parameters: [
      topic: [
        in: :path,
        description: "Короткое имя топика (order, cli, user, aaa, track, payment, msg, ipdr)",
        type: :string,
        example: "order",
        required: true
      ]
    ],
    request_body:
      {"Данные сущности", "application/json", %Schema{type: :object, description: "Произвольные поля сущности, соответствующие выбранному топику"}},
    responses: [
      accepted: {"Запрос принят и поставлен в очередь на публикацию", "application/json", IngestAcceptedResponse},
      bad_request: {"Неизвестный топик", "application/json", ErrorResponse},
      unprocessable_entity: {"В теле запроса отсутствует ключевое поле", "application/json", ErrorResponse},
      bad_gateway: {"Ошибка публикации в Kafka", "application/json", ErrorResponse},
      unauthorized: {"Токен авторизации отсутствует, недействителен или роль не data_provider", "application/json", ErrorResponse}
    ]
  )

  def create(conn, %{"topic" => topic} = params) do
    kafka_topic = "info." <> topic
    payload =
      Map.drop(params, ["topic"])
      |> Map.put("orgId", conn.assigns.current_operator.org_id)
    with true <- kafka_topic in CsvSwallower.Csv.topics(),
         key when not is_nil(key) <- Map.get(payload, CsvSwallower.key_field(kafka_topic)),
         :ok <- Producer.start_client(),
         :ok <- Producer.publish(kafka_topic, key, payload) do
      conn |> put_status(:accepted) |> json(%{status: "queued", topic: topic})
    else
      false -> conn |> put_status(:bad_request) |> json(%{error: "unknown topic: #{topic}"})
      nil -> conn |> put_status(:unprocessable_entity) |> json(%{error: "missing key field"})
      {:error, reason} -> conn |> put_status(:bad_gateway) |> json(%{error: inspect(reason)})
    end
  end

  operation(:create_file,
    summary: "Загрузка CSV-файла целиком",
    description:
      "Принимает CSV-файл со всеми топиками сразу (тот же формат, что и исторический механизм загрузки через личный кабинет) и разбирает его построчно, публикуя каждую строку в соответствующие Kafka-топики. Доступно только оператору с ролью data_provider.",
    request_body:
      {"CSV-файл", "multipart/form-data",
       %Schema{
         type: :object,
         properties: %{file: %Schema{type: :string, format: :binary, description: "CSV-файл с данными"}},
         required: [:file]
       }},
    responses: [
      accepted: {"Файл обработан", "application/json", CsvIngestResponse},
      bad_gateway: {"Ошибка публикации в Kafka", "application/json", ErrorResponse},
      unauthorized: {"Токен авторизации отсутствует, недействителен или роль не data_provider", "application/json", ErrorResponse}
    ]
  )

  def create_file(conn, %{"file" => %Plug.Upload{path: path}}) do
    case CsvSwallower.ingest(path, conn.assigns.current_operator.org_id) do
      {:error, reason} ->
        conn |> put_status(:bad_gateway) |> json(%{error: inspect(reason)})

      %{ok: ok, error: errors} ->
        conn |> put_status(:accepted) |> json(%{ok: ok, errors: length(errors)})
    end
  end

  operation(:show,
    summary: "Проверка статуса обработки ранее отправленной записи",
    description:
      "Проверяет, дошли ли ранее отправленные данные до итогового хранилища (то есть были ли они успешно вычитаны Kafka-consumer'ом и сохранены). Поддерживается не для всех топиков — aaa и ipdr не имеют однозначного бизнес-ключа на одну строку.",
    parameters: [
      topic: [
        in: :path,
        description: "Короткое имя топика (order, cli, user, track, payment, msg)",
        type: :string,
        example: "order",
        required: true
      ],
      id: [
        in: :path,
        description: "Бизнес-идентификатор записи (например, orderId)",
        type: :string,
        example: "ORD-001",
        required: true
      ]
    ],
    responses: [
      ok: {"Запись найдена и обработана", "application/json", VerificationResponse},
      not_found: {"Запись ещё не обработана либо не отправлялась", "application/json", VerificationResponse},
      bad_request: {"Топик не поддерживает проверку по id", "application/json", ErrorResponse},
      unauthorized: {"Токен авторизации отсутствует, недействителен или роль не data_provider", "application/json", ErrorResponse}
    ]
  )

  def show(conn, %{"topic" => topic, "id" => id}) do
    kafka_topic = "info." <> topic
    org_id = conn.assigns.current_operator.org_id

    with {module, field} <- schema_for(kafka_topic),
         record when not is_nil(record) <- Copm.Repo.get_by(module, [{field, id}, {:org_id, org_id}]) do
      conn |> put_status(:ok) |> json(%{status: "processed"})
    else
      nil -> conn |> put_status(:not_found) |> json(%{status: "not_found"})
      :error -> conn |> put_status(:bad_request) |> json(%{error: "topic not supported for verification"})
    end
  end

  defp schema_for("info.cli"), do: {Copm.Schemas.Client, :client_id}
  defp schema_for("info.user"), do: {Copm.Schemas.User, :user_id}
  defp schema_for("info.order"), do: {Copm.Schemas.Order, :order_id}
  defp schema_for("info.track"), do: {Copm.Schemas.TrackingEvent, :tracking_id}
  defp schema_for("info.payment"), do: {Copm.Schemas.Payment, :payment_id}
  defp schema_for("info.msg"), do: {Copm.Schemas.Message, :message_id}
  defp schema_for(_), do: :error
end
