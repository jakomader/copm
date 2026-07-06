defmodule Copm.Auth.ApiToken do
  use Ecto.Schema
  import Ecto.Changeset

  schema "api_tokens" do
    belongs_to :operator, Copm.Schemas.Operators
    field :token_hash, :string
    field :revoked_at, :utc_datetime

    timestamps()
  end

  def changeset(token, attrs) do
    token
    |> cast(attrs, [:operator_id, :token_hash, :revoked_at])
    |> validate_required([:operator_id, :token_hash])
    |> unique_constraint(:token_hash)
  end
end
