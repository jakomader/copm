defmodule CopmWeb.Schemas.CsvIngestResponse do
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "CsvIngestResponse",
    description: "Результат обработки загруженного CSV-файла",
    type: :object,
    properties: %{
      ok: %Schema{type: :integer, description: "Количество успешно обработанных строк", example: 8000},
      errors: %Schema{type: :integer, description: "Количество строк, обработанных с ошибкой", example: 0}
    },
    required: [:ok, :errors]
  })
end
