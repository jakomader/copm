defmodule CopmWeb.Schemas.VerificationResponse do
  require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "VerificationResponse",
    description: "Статус обработки ранее отправленной записи",
    type: :object,
    properties: %{
      status: %Schema{
        type: :string,
        description: "processed - запись найдена в итоговой таблице; not_found - ещё не обработана либо не отправлялась",
        enum: ["processed", "not_found"],
        example: "processed"
      }
    },
    required: [:status]
  })
end
