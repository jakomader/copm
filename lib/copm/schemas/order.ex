defmodule Copm.Schemas.Order do
  use Ecto.Schema
  import Ecto.Changeset

  alias Copm.Schemas.{Client, User, TrackingEvent, Payment, Message, Organizations}

  @primary_key false
  schema "orders" do
    field :order_id, :string, primary_key: true
    belongs_to :client, Client, foreign_key: :client_id, references: :client_id, type: :string
    belongs_to :user, User, foreign_key: :user_id, references: :user_id, type: :string
    belongs_to :organization, Organizations, foreign_key: :org_id, primary_key: true
    field :contract_id, :string
    field :order_status, :string
    field :order_type, :string
    field :created_at, :string
    field :confirmed_at, :string
    field :sender, :map
    field :receiver, :map
    field :route_from, :string
    field :route_to, :string
    field :transit_points, {:array, :string}
    field :carrier, :map
    field :flight_number, :string
    field :vehicle_number, :string
    field :awb_number, :string
    field :cmr_number, :string
    field :cargo_description, :string
    field :cargo_weight, :decimal
    field :cargo_volume, :decimal
    field :cargo_danger_class, :string
    field :cargo_special_conditions, :string
    field :insurance_info, :map
    field :customs_info, :map
    field :estimated_delivery_date, :string
    field :actual_delivery_date, :string

    has_many :tracking_events, TrackingEvent, foreign_key: :order_id, references: :order_id
    has_many :payments, Payment, foreign_key: :order_id, references: :order_id
    has_many :messages, Message, foreign_key: :related_order_id, references: :order_id

    timestamps()
  end

  @required ~w(order_id contract_id client_id user_id org_id order_status order_type created_at confirmed_at sender receiver route_from route_to carrier cargo_description cargo_weight estimated_delivery_date actual_delivery_date)a
  @optional ~w(transit_points flight_number vehicle_number awb_number cmr_number cargo_volume cargo_danger_class cargo_special_conditions insurance_info customs_info)a
  @actualize_fields ~w(
    contract_id client_id user_id order_status order_type created_at confirmed_at
    sender receiver route_from route_to carrier cargo_description cargo_weight
    estimated_delivery_date actual_delivery_date
  )a

  def changeset(order, attrs) do
    order
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required)
    |> validate_inclusion(:order_status, ~w(CREATED CONFIRMED IN_TRANSIT DELIVERED CANCELLED))
    |> validate_inclusion(:order_type, ~w(AIR AUTO MULTIMODAL INTERNATIONAL))
    |> foreign_key_constraint(:org_id)
  end

  def actualize_changeset(order, attrs) do
    present_keys = attrs |> Map.keys() |> Enum.map(&to_string/1)
    act_headers = Enum.map(@actualize_fields, &Atom.to_string/1)

    case present_keys -- act_headers do
      [] ->
        present_atoms = attrs |> Map.keys() |> Enum.map(&String.to_existing_atom/1)

        order
        |> cast(attrs, @actualize_fields)
        |> validate_required(present_atoms)
        |> validate_inclusion(:order_status, ~w(CREATED CONFIRMED IN_TRANSIT DELIVERED CANCELLED))
        |> validate_inclusion(:order_type, ~w(AIR AUTO MULTIMODAL INTERNATIONAL))
        |> then(fn cs ->
          if map_size(cs.changes) == 0,
            do: add_error(cs, :base, "нужно обновить хотя бы 1 поле"),
            else: cs
        end)

      extra ->
        order
        |> cast(attrs, [])
        |> add_error(:base, "неожиданные поля: #{inspect(extra)}")
    end
  end
end
