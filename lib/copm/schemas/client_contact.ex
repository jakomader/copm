defmodule Copm.Schemas.ClientContact do
  use Ecto.Schema
  import Ecto.Changeset

  alias Copm.Schemas.{Client, Organizations}

  schema "client_contacts" do
    belongs_to :client, Client, foreign_key: :client_id, references: :client_id, type: :string
    belongs_to :organization, Organizations, foreign_key: :org_id
    field :phone, :string
    field :email, :string

    timestamps()
  end

  def changeset(contact, attrs) do
    contact
    |> cast(attrs, ~w(client_id org_id phone email)a)
    |> validate_required(~w(client_id org_id phone email)a)
    |> foreign_key_constraint(:org_id)
    |> foreign_key_constraint(:client_id, name: :client_contacts_org_client_fkey)
  end
end
