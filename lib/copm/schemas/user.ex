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
    field :user_starts_at, :string
    field :user_ends_at, :string

    has_many :auth_events, AuthEvent, foreign_key: :user_id, references: :user_id
    has_many :orders, Order, foreign_key: :user_id, references: :user_id
    has_many :payments, Payment, foreign_key: :user_id, references: :user_id
    has_many :conversations, Conversation, foreign_key: :user_id, references: :user_id

    timestamps()
  end

  @required ~w(user_id client_id org_id login person user_starts_at)a
  @optional ~w(user_ends_at)a
  @actualize_fields ~w(client_id login person user_starts_at)a

  def changeset(user, attrs) do
    user
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required)
    |> unique_constraint(:login, name: :users_org_id_login_index)
    |> foreign_key_constraint(:org_id)
  end

  def actualize_changeset(user, attrs) do
    present_keys = attrs |> Map.keys() |> Enum.map(&to_string/1)
    act_headers = Enum.map(@actualize_fields, &Atom.to_string/1)

    case present_keys -- act_headers do
      [] ->
        present_atoms = attrs |> Map.keys() |> Enum.map(&String.to_existing_atom/1)

        user
        |> cast(attrs, @actualize_fields)
        |> validate_required(present_atoms)
        |> unique_constraint(:login, name: :users_org_id_login_index)
        |> then(fn cs ->
          if map_size(cs.changes) == 0,
            do: add_error(cs, :base, "нужно обновить хотя бы 1 поле"),
            else: cs
        end)

      extra ->
        user
        |> cast(attrs, [])
        |> add_error(:base, "неожиданные поля: #{inspect(extra)}")
    end
  end
end
