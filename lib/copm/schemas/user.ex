defmodule Copm.Schemas.User do
  use Ecto.Schema
  import Ecto.Changeset

  alias Copm.Schemas.{Client, AuthEvent, Order, Payment, Conversation}

  @primary_key {:user_id, :string, autogenerate: false}
  schema "users" do
    belongs_to :client, Client, foreign_key: :client_id, references: :client_id, type: :string
    field :login, :string
    field :person, :map
    field :user_starts_at, :utc_datetime
    field :user_ends_at, :utc_datetime

    has_many :auth_events, AuthEvent, foreign_key: :user_id
    has_many :orders, Order, foreign_key: :user_id
    has_many :payments, Payment, foreign_key: :user_id
    has_many :conversations, Conversation, foreign_key: :user_id

    timestamps()
  end

  @required ~w(user_id client_id login person user_starts_at)a
  @optional ~w(user_ends_at)a

  def changeset(user, attrs) do
    user
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required)
    |> unique_constraint(:login)
  end
end
