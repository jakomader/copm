defmodule Copm.Auth.ApiToken do
  use Ecto.Schema
  import Ecto.Changeset

  schema "api_tokens" do
    field :name, :string
    field :token_hash, :string
    field :revoked_at, :utc_datetime

    timestamps()
  end

  def changeset(token, attrs) do
    token
    |> cast(attrs, [:name, :token_hash, :revoked_at])
    |> validate_required([:name, :token_hash])
    |> unique_constraint(:token_hash)
  end
end
