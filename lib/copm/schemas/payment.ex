defmodule Copm.Schemas.Payment do
  use Ecto.Schema
  import Ecto.Changeset

  alias Copm.Schemas.{Order, Client, User}

  @primary_key {:payment_id, :string, autogenerate: false}
  schema "payments" do
    belongs_to :order, Order, foreign_key: :order_id, references: :order_id, type: :string
    belongs_to :client, Client, foreign_key: :client_id, references: :client_id, type: :string
    belongs_to :user, User, foreign_key: :user_id, references: :user_id, type: :string
    field :payment_ts, :utc_datetime
    field :payment_type, :string
    field :payment_method, :string
    field :amount, :decimal
    field :currency, :string
    field :invoice_number, :string
    field :from_bank_info, :map
    field :to_bank_info, :map
    field :payment_status, :string
    field :external_payment_id, :string
    field :session_id, :string
    field :ip_address, :string

    timestamps()

  end

  @required ~w(payment_id order_id client_id user_id payment_ts payment_type payment_method amount currency invoice_number from_bank_info to_bank_info payment_status session_id ip_address)a
  @optional ~w(external_payment_id)a

  def changeset(payment, attrs) do
    payment
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required)
    |> validate_inclusion(:payment_type, ~w(INVOICE PREPAYMENT POSTPAYMENT REFUND))
    |> validate_inclusion(:payment_method, ~w(BANK_TRANSFER CARD ACCOUNT_DEBIT))
    |> validate_inclusion(:payment_status, ~w(PENDING CONFIRMED FAILED REFUNDED))
  end
end
