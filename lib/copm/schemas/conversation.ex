defmodule Copm.Schemas.Conversation do
  use Ecto.Schema
  import Ecto.Changeset

  alias Copm.Schemas.{Client, User, Message}

  @primary_key {:conversation_id, :string, autogenerate: false}
  schema "conversations" do
    belongs_to :client, Client, foreign_key: :client_id, references: :client_id, type: :string
    belongs_to :user, User, foreign_key: :user_id, references: :user_id, type: :string
    field :session_id, :string
    field :starts_at, :utc_datetime
    field :ends_at, :utc_datetime
    field :channel, :string

    has_many :messages, Message, foreign_key: :conversation_id

    timestamps()
  end

  @required ~w(conversation_id client_id user_id session_id starts_at channel)a
  @optional ~w(ends_at)a

  def changeset(conv, attrs) do
    conv
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required)
    |> validate_inclusion(:channel, ~w(CHAT_LK EMAIL PHONE MESSENGER))
    |> foreign_key_constraint(:client_id)
    |> foreign_key_constraint(:user_id)
  end
end
