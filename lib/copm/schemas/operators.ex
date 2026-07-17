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
    belongs_to :organization, Copm.Schemas.Organizations, foreign_key: :org_id
    timestamps()
  end

  def changeset(op, attrs) do
    op
    |> cast(attrs, [:login, :role, :password, :name, :status, :purpose, :org_id])
    |> validate_required([:login, :role, :password, :name])
    |> validate_inclusion(:role, ~w(data_provider queries_only admin))
    |> validate_org_required_for_provider()
    |> validate_inclusion(:status, ~w(active blocked))
    |> validate_length(:password, min: 12)
    |> unique_constraint(:login)
    |> foreign_key_constraint(:org_id)
    |> put_password_hash()
  end
  def update_changeset(op, attrs) do
    op
    |> cast(attrs, [:login, :role, :password, :name, :status, :purpose, :org_id])
    |> validate_required([:login, :role, :name, :status])
    |> validate_inclusion(:status, ~w(active blocked))
    |> validate_inclusion(:role, ~w(data_provider queries_only admin))
    |> validate_org_required_for_provider()
    |> foreign_key_constraint(:org_id)
    |> put_password_hash()

  end
  defp validate_org_required_for_provider(changeset) do
    case get_field(changeset, :role) do
      "data_provider" -> changeset |> validate_required([:org_id])
      _ -> changeset
    end
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
