defmodule CopmWeb.Schemas.IngestAcceptedResponse do
require OpenApiSpex
  alias OpenApiSpex.Schema

  OpenApiSpex.schema(%{
    title: "IngestAcceptedResponse",
    type: :object,
    properties: %{
      status: %Schema{type: :string, example: "queued"},
      topic: %Schema{type: :string, example: "order"}
    },
    required: [:status, :topic]
  })
end
