defmodule Copm.Schemas.Organizations do
  use Ecto.Schema
  import Ecto.Changeset
  schema "organizations" do
    field :org_name, :string
    timestamps()
  end

  def changeset(organization, attrs) do
    organization
    |> cast(attrs, [:org_name])
    |> validate_required([:org_name])
    |> unique_constraint(:org_name)
  end
end
