defmodule Copm.Schemas.IpdrRecord do
  use Ecto.Schema
  import Ecto.Changeset

  alias Copm.Schemas.Organizations

  schema "ipdr_records" do
    belongs_to :organization, Organizations, foreign_key: :org_id
    field :ts, :utc_datetime
    field :source_ip, :string
    field :source_port, :integer
    field :destination_ip, :string
    field :destination_port, :integer
    field :protocol, :string
    field :flag, :string
    field :bytes_transferred, :integer

    timestamps()
  end

  @required ~w(org_id ts source_ip source_port destination_ip destination_port protocol bytes_transferred)a
  @optional ~w(flag)a

  def changeset(record, attrs) do
    record
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required)
    |> validate_inclusion(:protocol, ~w(TCP UDP))
    |> validate_inclusion(:flag, ~w(SYN FIN))
    |> foreign_key_constraint(:org_id)
  end
end
