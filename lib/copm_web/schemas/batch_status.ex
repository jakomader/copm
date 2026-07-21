defmodule CopmWeb.Schemas.BatchProcessingResponse do
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "BatchProcessingResponse",
    description: "Батч ещё обрабатывается - не все записи дошли до итогового хранилища",
    type: :object,
    properties: %{
      status: %Schema{type: :string, enum: ["processing"], example: "processing"},
      total: %Schema{type: :integer, description: "Всего записей в батче", example: 500},
      processed: %Schema{type: :integer, description: "Сколько записей уже обработано (успешно или с ошибкой)", example: 320}
    },
    required: [:status, :total, :processed]
  })
end

defmodule CopmWeb.Schemas.BatchDeliveredResponse do
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "BatchDeliveredResponse",
    description: "Батч полностью обработан, ошибок нет",
    type: :object,
    properties: %{
      status: %Schema{type: :string, enum: ["Доставлено"], example: "Доставлено"}
    },
    required: [:status]
  })
end

defmodule CopmWeb.Schemas.BatchErrorItem do
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "BatchErrorItem",
    type: :object,
    properties: %{
      businessKey: %Schema{
        type: :string,
        description: "Бизнес-ключ проблемной записи (clientId, orderId и т.п.), либо \"item #N\" - порядковый номер в пакете, если ключа не было вовсе",
        example: "CLI-001"
      },
      message: %Schema{type: :string, description: "Текст ошибки", example: "нужно обновить хотя бы 1 поле"}
    },
    required: [:businessKey, :message]
  })
end

defmodule CopmWeb.Schemas.TransactionItem do
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "TransactionItem",
    description: "Одна пакетная загрузка (транзакция) организации",
    type: :object,
    properties: %{
      batchId: %Schema{type: :string, description: "Идентификатор батча", example: "8c3001a5-f9cf-4838-98ca-590dd129aec0"},
      topic: %Schema{type: :string, description: "Kafka-топик, в который отправлен батч", example: "info.order"},
      total: %Schema{type: :integer, description: "Всего записей в батче", example: 500},
      processed: %Schema{type: :integer, description: "Сколько записей уже обработано", example: 500},
      status: %Schema{
        type: :string,
        description: "processing / Доставлено / Ошибки присутствуют / Ошибки присутствуют, не все данные обработаны",
        example: "Доставлено"
      },
      insertedAt: %Schema{type: :string, format: :"date-time", description: "Когда батч был создан"}
    },
    required: [:batchId, :topic, :total, :processed, :status, :insertedAt]
  })
end

defmodule CopmWeb.Schemas.TransactionListResponse do
  require OpenApiSpex
  alias OpenApiSpex.Schema
  alias CopmWeb.Schemas.TransactionItem

  OpenApiSpex.schema(%{
    title: "TransactionListResponse",
    description: "Список всех пакетных загрузок (транзакций) организации текущего оператора, от новых к старым",
    type: :object,
    properties: %{
      transactions: %Schema{type: :array, items: TransactionItem}
    },
    required: [:transactions]
  })
end

defmodule CopmWeb.Schemas.BatchErrorResponse do
  require OpenApiSpex
  alias OpenApiSpex.Schema
  alias CopmWeb.Schemas.BatchErrorItem

  OpenApiSpex.schema(%{
    title: "BatchErrorResponse",
    description: "Батч обработан (полностью или частично) - есть ошибки хотя бы по одной записи",
    type: :object,
    properties: %{
      status: %Schema{type: :string, example: "Ошибки присутствуют"},
      error: %Schema{type: :array, items: BatchErrorItem, description: "Список ошибок по отдельным записям"}
    },
    required: [:status, :error]
  })
end
