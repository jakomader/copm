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

  @actualize_fields ~w(email)a

  def changeset(contact, attrs) do
    contact
    |> cast(attrs, ~w(client_id org_id phone email)a)
    |> validate_required(~w(client_id org_id phone email)a)
    |> foreign_key_constraint(:org_id)
    |> foreign_key_constraint(:client_id, name: :client_contacts_org_client_fkey)
  end

  def actualize_changeset(contact, attrs) do
    present_keys = attrs |> Map.keys() |> Enum.map(&to_string/1)
    act_headers = Enum.map(@actualize_fields, &Atom.to_string/1)

    case present_keys -- act_headers do
      [] ->
        present_atoms = attrs |> Map.keys() |> Enum.map(&String.to_existing_atom/1)

        contact
        |> cast(attrs, @actualize_fields)
        |> validate_required(present_atoms)
        |> then(fn cs ->
          if map_size(cs.changes) == 0,
            do: add_error(cs, :base, "нужно обновить хотя бы 1 поле"),
            else: cs
        end)

      extra ->
        contact
        |> cast(attrs, [])
        |> add_error(:base, "неожиданные поля: #{inspect(extra)}")
    end
  end
end
