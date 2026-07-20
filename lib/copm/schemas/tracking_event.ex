defmodule Copm.Schemas.TrackingEvent do
  use Ecto.Schema
  import Ecto.Changeset

  alias Copm.Schemas.{Order, Organizations}

  @primary_key false
  schema "tracking_events" do
    field :tracking_id, :string, primary_key: true
    belongs_to :order, Order, foreign_key: :order_id, references: :order_id, type: :string
    belongs_to :organization, Organizations, foreign_key: :org_id, primary_key: true
    field :event_ts, :string
    field :status_code, :string
    field :status_description, :string
    field :location, :map
    field :operator_id, :string
    field :scanned_device_id, :string

    timestamps()
  end

  @required ~w(tracking_id order_id org_id event_ts status_code location)a
  @optional ~w(status_description operator_id scanned_device_id)a
  @actualize_fields ~w(order_id event_ts status_code location)a

  def changeset(event, attrs) do
    event
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required)
    |> validate_inclusion(:status_code, ~w(PICKUP WAREHOUSE_IN DEPARTED ARRIVED DELIVERED))
    |> foreign_key_constraint(:org_id)
  end

  def actualize_changeset(event, attrs) do
    present_keys = attrs |> Map.keys() |> Enum.map(&to_string/1)
    act_headers = Enum.map(@actualize_fields, &Atom.to_string/1)

    case present_keys -- act_headers do
      [] ->
        present_atoms = attrs |> Map.keys() |> Enum.map(&String.to_existing_atom/1)

        event
        |> cast(attrs, @actualize_fields)
        |> validate_required(present_atoms)
        |> validate_inclusion(:status_code, ~w(PICKUP WAREHOUSE_IN DEPARTED ARRIVED DELIVERED))
        |> then(fn cs ->
          if map_size(cs.changes) == 0,
            do: add_error(cs, :base, "нужно обновить хотя бы 1 поле"),
            else: cs
        end)

      extra ->
        event
        |> cast(attrs, [])
        |> add_error(:base, "неожиданные поля: #{inspect(extra)}")
    end
  end
end
