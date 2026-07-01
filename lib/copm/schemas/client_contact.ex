defmodule Copm.Schemas.ClientContact do
  use Ecto.Schema
  import Ecto.Changeset

  alias Copm.Schemas.Client

  schema "client_contacts" do
    belongs_to :client, Client, foreign_key: :client_id, references: :client_id, type: :string
    field :phone, :string
    field :email, :string

    timestamps()
  end

  def changeset(contact, attrs) do
    contact
    |> cast(attrs, ~w(client_id phone email)a)
    |> validate_required(~w(client_id phone email)a)
  end
end
