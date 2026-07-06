defmodule Copm.Schemas.Operators do
  use Ecto.Schema

  import Ecto.Changeset

  schema "operators" do
    field :login, :string
    field :password_hash, :string
    field :role, :string
    field :password, :string, virtual: true

    timestamps()
  end

  def changeset(op, attrs) do
    op
    |> cast(attrs, [:login, :role, :password])
    |> validate_required([:login, :role, :password])
    |> validate_inclusion(:role, ~w(data_provider queries_only))
    |> validate_length(:password, min: 12)
    |> unique_constraint(:login)
    |> put_password_hash()
  end

  defp put_password_hash(%Ecto.Changeset{valid?: true} = changeset) do
    password = get_change(changeset, :password) |> Bcrypt.hash_pwd_salt()
    put_change(changeset, :password_hash, password)
  end
  defp put_password_hash(changeset), do: changeset
end
