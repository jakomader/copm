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
    field :date_begin, :string
    field :date_end, :string

    timestamps()

  end

  @required ~w(client_id org_id full_name inn position role)a
  @optional ~w(date_begin date_end)a
  @actualize_fields ~w(full_name position role)a


  def changeset(relation, attrs) do
    relation
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required)
    |> validate_inclusion(:role, ~w(SENDER RECEIVER PAYER))
    |> foreign_key_constraint(:org_id)
    |> foreign_key_constraint(:client_id, name: :client_relations_org_client_fkey)
  end

  def actualize_changeset(relation, attrs) do
    present_keys = attrs |> Map.keys() |> Enum.map(&to_string/1)
    act_headers = Enum.map(@actualize_fields, &Atom.to_string/1)

    case present_keys -- act_headers do
      [] ->
        present_atoms = attrs |> Map.keys() |> Enum.map(&String.to_existing_atom/1)

        relation
        |> cast(attrs, @actualize_fields)
        |> validate_required(present_atoms)
        |> validate_inclusion(:role, ~w(SENDER RECEIVER PAYER))
        |> then(fn cs ->
          if map_size(cs.changes) == 0,
            do: add_error(cs, :base, "нужно обновить хотя бы 1 поле"),
            else: cs
        end)

      extra ->
        relation
        |> cast(attrs, [])
        |> add_error(:base, "неожиданные поля: #{inspect(extra)}")
    end
  end
end
