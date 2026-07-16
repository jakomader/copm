defmodule Copm.Schemas.Operators do
  use Ecto.Schema

  import Ecto.Changeset

  schema "operators" do
    field :login, :string
    field :password_hash, :string
    field :name, :string
    field :status, :string, default: "active"
    field :purpose, :string
    field :role, :string
    field :password, :string, virtual: true

    timestamps()
  end

  def changeset(op, attrs) do
    op
    |> cast(attrs, [:login, :role, :password, :name, :status, :purpose])
    |> validate_required([:login, :role, :password, :name])
    |> validate_inclusion(:role, ~w(data_provider queries_only admin))
    |> validate_inclusion(:status, ~w(active blocked))
    |> validate_length(:password, min: 12)
    |> unique_constraint(:login)
    |> put_password_hash()
  end
  def update_changeset(op, attrs) do
    op
    |> cast(attrs, [:login, :role, :password, :name, :status, :purpose])
    |> validate_required([:login, :role, :name, :status])
    |> validate_inclusion(:status, ~w(active blocked))
    |> validate_inclusion(:role, ~w(data_provider queries_only admin))
    |> put_password_hash()

  end
  defp put_password_hash(%Ecto.Changeset{valid?: true} = changeset) do
    case get_change(changeset, :password) do
      nil -> changeset
      password -> password = password |> Bcrypt.hash_pwd_salt()
      put_change(changeset, :password_hash, password)

    end
  end
  defp put_password_hash(changeset), do: changeset
end
