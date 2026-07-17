defmodule Copm.Schemas.ClientRelation do
  use Ecto.Schema
  import Ecto.Changeset

  alias Copm.Schemas.{Client, Organizations}

  schema "client_relations" do
    belongs_to :client, Client, foreign_key: :client_id, references: :client_id, type: :string
    belongs_to :organization, Organizations, foreign_key: :org_id
    field :full_name, :string
    field :inn, :string
    field :position, :string
    field :role, :string
    field :date_begin, :date
    field :date_end, :date

    timestamps()

  end

  @required ~w(client_id org_id full_name inn position role)a
  @optional ~w(date_begin date_end)a


  def changeset(relation, attrs) do
    relation
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required)
    |> validate_inclusion(:role, ~w(SENDER RECEIVER PAYER))
    |> foreign_key_constraint(:org_id)
    |> foreign_key_constraint(:client_id, name: :client_relations_org_client_fkey)
  end

end
