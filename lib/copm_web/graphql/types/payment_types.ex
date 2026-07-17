defmodule CopmWeb.GraphQL.Types.PaymentTypes do
  use Absinthe.Schema.Notation

  alias CopmWeb.GraphQL.Resolvers.PaymentResolver

  object :payment do
    field :payment_id, non_null(:string)
    field :org_id, non_null(:integer)
    field :order_id, non_null(:string)
    field :client_id, non_null(:string)
    field :user_id, non_null(:string)
    field :payment_ts, non_null(:string)
    field :payment_type, non_null(:string)
    field :payment_method, non_null(:string)
    field :amount, non_null(:float)
    field :currency, non_null(:string)
    field :invoice_number, non_null(:string)
    field :from_bank_info, non_null(:json)
    field :to_bank_info, non_null(:json)
    field :payment_status, non_null(:string)
    field :external_payment_id, :string
    field :session_id, non_null(:string)
    field :ip_address, non_null(:string)

    field :order, :order, resolve: &PaymentResolver.scoped_order/3
    field :client, :client, resolve: &PaymentResolver.scoped_client/3
    field :user, :user, resolve: &PaymentResolver.scoped_user/3
  end

  object :payment_queries do
    field :payment, :payment do
      arg :org_id, non_null(:integer)
      arg :payment_id, non_null(:string)
      resolve &PaymentResolver.get_payment/3
    end

    field :payments, list_of(:payment) do
      arg :org_id, :integer
      arg :order_id, :string
      arg :client_id, :string
      arg :status, :string
      arg :limit, :integer, default_value: 20
      arg :offset, :integer, default_value: 0
      resolve &PaymentResolver.list_payments/3
    end
  end
end
