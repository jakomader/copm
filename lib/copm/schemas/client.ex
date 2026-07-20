defmodule Copm.Schemas.Client do
  use Ecto.Schema
  import Ecto.Changeset

  alias Copm.Schemas.{ClientRelation, ClientContact, User, Order, Payment, Conversation, Organizations}

  @primary_key false
  schema "clients" do
    field :client_id, :string, primary_key: true
    belongs_to :organization, Organizations, foreign_key: :org_id, primary_key: true
    field :client_status, :string
    field :registration_date, :string
    field :full_name, :string
    field :short_name, :string
    field :inn, :string
    field :kpp, :string
    field :ogrn, :string
    field :okpo, :string
    field :tax_agency_code, :string
    field :legal_address, :map
    field :postal_address, :map
    field :reg_country_code, :string
    field :is_foreign, :boolean, default: false
    field :economic_sector, :string
    field :bank_info, :map

    has_many :relations, ClientRelation, foreign_key: :client_id, references: :client_id
    has_many :contacts, ClientContact, foreign_key: :client_id, references: :client_id
    has_many :users, User, foreign_key: :client_id, references: :client_id
    has_many :orders, Order, foreign_key: :client_id, references: :client_id
    has_many :payments, Payment, foreign_key: :client_id, references: :client_id
    has_many :conversations, Conversation, foreign_key: :client_id, references: :client_id

    timestamps()
  end
  @actualize_fields ~w(
    client_status registration_date full_name inn ogrn
    legal_address reg_country_code is_foreign bank_info
  )a
  @required ~w(client_id org_id client_status registration_date full_name inn ogrn legal_address reg_country_code is_foreign bank_info)a
  @optional ~w(short_name kpp okpo tax_agency_code postal_address economic_sector)a

  def changeset(client, attrs) do
    client
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required)
    |> validate_inclusion(:client_status, ~w(ACTIVE BLOCKED ARCHIVED))
    |> foreign_key_constraint(:org_id)
  end
  def actualize_changeset(client, attrs) do
    present_keys = attrs |> Map.keys() |> Enum.map(&to_string/1)

    act_headers = Enum.map(@actualize_fields, &Atom.to_string/1)
    case present_keys -- act_headers do
      [] ->
        present_atoms = attrs |> Map.keys() |> Enum.map(&String.to_existing_atom/1)
        client
        |> cast(attrs, @actualize_fields)
        |> validate_required(present_atoms)
        |> then(fn cs -> if map_size(cs.changes) == 0 do add_error(cs, :base, "нужно обновить хотя бы 1 поле") else cs end end)
      extra ->
        client
        |> cast(attrs, [])
        |> add_error(:base, "неожиданные поля: #{inspect(extra)}")
    end
  end
end
