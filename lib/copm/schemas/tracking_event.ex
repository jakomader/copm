defmodule Copm.Schemas.TrackingEvent do
  use Ecto.Schema
  import Ecto.Changeset

  alias Copm.Schemas.Order

  @primary_key {:tracking_id, :string, autogenerate: false}
  schema "tracking_events" do
    belongs_to :order, Order, foreign_key: :order_id, references: :order_id, type: :string
    field :event_ts, :utc_datetime
    field :status_code, :string
    field :status_description, :string
    field :location, :map
    field :operator_id, :string
    field :scanned_device_id, :string

    timestamps()
  end

  @required ~w(tracking_id order_id event_ts status_code location)a
  @optional ~w(status_description operator_id scanned_device_id)a

  def changeset(event, attrs) do
    event
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required)
    |> validate_inclusion(:status_code, ~w(PICKUP WAREHOUSE_IN DEPARTED ARRIVED DELIVERED))
    |> foreign_key_constraint(:order_id)
  end
end
