defmodule CopmWeb.GraphQL.Types.OrderTypes do
  use Absinthe.Schema.Notation

  alias CopmWeb.GraphQL.Resolvers.OrderResolver

  object :order do
    field :order_id, non_null(:string)
    field :org_id, non_null(:integer)
    field :contract_id, non_null(:string)
    field :client_id, non_null(:string)
    field :user_id, non_null(:string)
    field :order_status, non_null(:string)
    field :order_type, non_null(:string)
    field :created_at, non_null(:string)
    field :confirmed_at, non_null(:string)
    field :sender, non_null(:json)
    field :receiver, non_null(:json)
    field :route_from, non_null(:string)
    field :route_to, non_null(:string)
    field :transit_points, list_of(:string)
    field :carrier, non_null(:json)
    field :flight_number, :string
    field :vehicle_number, :string
    field :awb_number, :string
    field :cmr_number, :string
    field :cargo_description, non_null(:string)
    field :cargo_weight, non_null(:float)
    field :cargo_volume, :float
    field :cargo_danger_class, non_null(:string)
    field :cargo_special_conditions, :string
    field :insurance_info, :json
    field :customs_info, :json
    field :estimated_delivery_date, non_null(:string)
    field :actual_delivery_date, non_null(:string)

    field :client, :client, resolve: &OrderResolver.scoped_client/3
    field :user, :user, resolve: &OrderResolver.scoped_user/3
    field :tracking_events, list_of(:tracking_event), resolve: &OrderResolver.scoped_tracking_events/3
    field :payments, list_of(:payment), resolve: &OrderResolver.scoped_payments/3
  end

  object :order_queries do
    field :order, :order do
      arg :org_id, non_null(:integer)
      arg :order_id, non_null(:string)
      resolve &OrderResolver.get_order/3
    end

    field :orders, list_of(:order) do
      arg :org_id, :integer
      arg :client_id, :string
      arg :user_id, :string
      arg :status, :string
      arg :order_type, :string
      arg :limit, :integer, default_value: 20
      arg :offset, :integer, default_value: 0
      resolve &OrderResolver.list_orders/3
    end
  end
end
