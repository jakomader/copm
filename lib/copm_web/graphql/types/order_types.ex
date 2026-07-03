defmodule CopmWeb.GraphQL.Types.OrderTypes do
  use Absinthe.Schema.Notation
  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  alias CopmWeb.GraphQL.Resolvers.OrderResolver

  object :order do
    field :order_id, non_null(:string)
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

    field :client, :client, resolve: dataloader(Copm.Repo)
    field :user, :user, resolve: dataloader(Copm.Repo)
    field :tracking_events, list_of(:tracking_event), resolve: dataloader(Copm.Repo)
    field :payments, list_of(:payment), resolve: dataloader(Copm.Repo)
  end

  object :order_queries do
    field :order, :order do
      arg :order_id, non_null(:string)
      resolve &OrderResolver.get_order/3
    end

    field :orders, list_of(:order) do
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
