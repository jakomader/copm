defmodule CopmWeb.Schemas.ErrorResponse do
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "ErrorResponse",
    description: "Ошибка обработки запроса",
    type: :object,
    properties: %{
      error: %Schema{type: :string, description: "Текст ошибки", example: "unknown topic: bogus"}
    },
    required: [:error]
  })
end
