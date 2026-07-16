defmodule Copm.Auth.RefreshToken do
  use Ecto.Schema
  import Ecto.Changeset

  schema "refresh_tokens" do
    belongs_to :operator, Copm.Schemas.Operators
    field :token_hash, :string
    field :expires_at, :utc_datetime
    field :revoked_at, :utc_datetime
    belongs_to :replaced_with, __MODULE__, foreign_key: :replaced_with_id

    timestamps()
  end

  def changeset(token, attrs) do
    token
    |> cast(attrs, [:operator_id, :token_hash, :expires_at, :revoked_at, :replaced_with_id])
    |> validate_required([:operator_id, :token_hash, :expires_at])
    |> unique_constraint(:token_hash)
  end
end
