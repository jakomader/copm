defmodule Copm.Schemas.User do
  use Ecto.Schema
  import Ecto.Changeset

  alias Copm.Schemas.{Client, AuthEvent, Order, Payment, Conversation, Organizations}

  @primary_key false
  schema "users" do
    field :user_id, :string, primary_key: true
    belongs_to :client, Client, foreign_key: :client_id, references: :client_id, type: :string
    belongs_to :organization, Organizations, foreign_key: :org_id, primary_key: true
    field :login, :string
    field :person, :map
    field :user_starts_at, :utc_datetime
    field :user_ends_at, :utc_datetime

    has_many :auth_events, AuthEvent, foreign_key: :user_id, references: :user_id
    has_many :orders, Order, foreign_key: :user_id, references: :user_id
    has_many :payments, Payment, foreign_key: :user_id, references: :user_id
    has_many :conversations, Conversation, foreign_key: :user_id, references: :user_id

    timestamps()
  end

  @required ~w(user_id client_id org_id login person user_starts_at)a
  @optional ~w(user_ends_at)a

  def changeset(user, attrs) do
    user
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required)
    |> unique_constraint(:login)
    |> foreign_key_constraint(:client_id, name: :users_org_client_fkey)
    |> foreign_key_constraint(:org_id)
  end
end
