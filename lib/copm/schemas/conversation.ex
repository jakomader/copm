defmodule Copm.Schemas.Conversation do
  use Ecto.Schema
  import Ecto.Changeset

  alias Copm.Schemas.{Client, User, Message, Organizations}

  @primary_key false
  schema "conversations" do
    field :conversation_id, :string, primary_key: true
    belongs_to :client, Client, foreign_key: :client_id, references: :client_id, type: :string
    belongs_to :user, User, foreign_key: :user_id, references: :user_id, type: :string
    belongs_to :organization, Organizations, foreign_key: :org_id, primary_key: true
    field :session_id, :string
    field :starts_at, :string
    field :ends_at, :string
    field :channel, :string

    has_many :messages, Message, foreign_key: :conversation_id, references: :conversation_id

    timestamps()
  end

  @required ~w(conversation_id client_id user_id org_id session_id starts_at channel)a
  @optional ~w(ends_at)a
  @actualize_fields ~w(client_id user_id session_id starts_at channel)a

  def changeset(conv, attrs) do
    conv
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required)
    |> validate_inclusion(:channel, ~w(CHAT_LK EMAIL PHONE MESSENGER))
    |> foreign_key_constraint(:org_id)
  end

  def actualize_changeset(conv, attrs) do
    present_keys = attrs |> Map.keys() |> Enum.map(&to_string/1)
    act_headers = Enum.map(@actualize_fields, &Atom.to_string/1)

    case present_keys -- act_headers do
      [] ->
        present_atoms = attrs |> Map.keys() |> Enum.map(&String.to_existing_atom/1)

        conv
        |> cast(attrs, @actualize_fields)
        |> validate_required(present_atoms)
        |> validate_inclusion(:channel, ~w(CHAT_LK EMAIL PHONE MESSENGER))
        |> then(fn cs ->
          if map_size(cs.changes) == 0,
            do: add_error(cs, :base, "нужно обновить хотя бы 1 поле"),
            else: cs
        end)

      extra ->
        conv
        |> cast(attrs, [])
        |> add_error(:base, "неожиданные поля: #{inspect(extra)}")
    end
  end
end
