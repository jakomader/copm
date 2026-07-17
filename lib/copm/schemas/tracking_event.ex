defmodule Copm.Schemas.TrackingEvent do
  use Ecto.Schema
  import Ecto.Changeset

  alias Copm.Schemas.{Order, Organizations}

  @primary_key false
  schema "tracking_events" do
    field :tracking_id, :string, primary_key: true
    belongs_to :order, Order, foreign_key: :order_id, references: :order_id, type: :string
    belongs_to :organization, Organizations, foreign_key: :org_id, primary_key: true
    field :event_ts, :utc_datetime
    field :status_code, :string
    field :status_description, :string
    field :location, :map
    field :operator_id, :string
    field :scanned_device_id, :string

    timestamps()
  end

  @required ~w(tracking_id order_id org_id event_ts status_code location)a
  @optional ~w(status_description operator_id scanned_device_id)a

  def changeset(event, attrs) do
    event
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required)
    |> validate_inclusion(:status_code, ~w(PICKUP WAREHOUSE_IN DEPARTED ARRIVED DELIVERED))
    |> foreign_key_constraint(:order_id, name: :tracking_events_org_order_fkey)
    |> foreign_key_constraint(:org_id)
  end
end
