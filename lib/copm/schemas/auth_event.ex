defmodule Copm.Schemas.AuthEvent do
  use Ecto.Schema
  import Ecto.Changeset

  alias Copm.Schemas.User

  schema "auth_events" do
    belongs_to :user, User, foreign_key: :user_id, references: :user_id, type: :string
    field :session_id, :string
    field :session_ts, :utc_datetime
    field :event_type, :string
    field :ip_address, :map
    field :user_agent, :string
    field :device_id, :string
    field :geolocation, :string

    timestamps()
  end

  @required ~w(user_id session_id session_ts event_type ip_address user_agent)a
  @optional ~w(device_id geolocation)a

  def changeset(event, attrs) do
    event
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required)
    |> validate_inclusion(:event_type, ~w(LOGIN LOGOUT PASSWORD_CHANGE))
  end
end
