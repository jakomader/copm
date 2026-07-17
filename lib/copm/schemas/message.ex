defmodule Copm.Schemas.Message do
  use Ecto.Schema
  import Ecto.Changeset

  alias Copm.Schemas.{Conversation, Order, Organizations}

  @primary_key false
  schema "messages" do
    field :message_id, :string, primary_key: true
    belongs_to :conversation, Conversation, foreign_key: :conversation_id, references: :conversation_id, type: :string
    belongs_to :organization, Organizations, foreign_key: :org_id, primary_key: true
    field :message_ts, :utc_datetime
    field :message_text, :string
    field :attachments, {:array, :string}
    field :operator_login, :string
    field :ip_address, :string
    belongs_to :related_order, Order, foreign_key: :related_order_id, references: :order_id, type: :string

    timestamps()
  end

  @required ~w(message_id conversation_id org_id message_ts message_text ip_address)a
  @optional ~w(attachments operator_login related_order_id)a

  def changeset(msg, attrs) do
    msg
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required)
    |> foreign_key_constraint(:conversation_id, name: :messages_org_conversation_fkey)
    |> foreign_key_constraint(:org_id)
  end
end
