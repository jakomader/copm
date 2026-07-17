defmodule CopmWeb.GraphQL.Types.TrackingTypes do
  use Absinthe.Schema.Notation

  alias CopmWeb.GraphQL.Resolvers.TrackingResolver

  object :tracking_event do
    field :tracking_id, non_null(:string)
    field :org_id, non_null(:integer)
    field :order_id, non_null(:string)
    field :event_ts, non_null(:string)
    field :status_code, non_null(:string)
    field :status_description, :string
    field :location, non_null(:json)
    field :operator_id, :string
    field :scanned_device_id, :string

    field :order, :order, resolve: &TrackingResolver.scoped_order/3
  end

  object :tracking_queries do
    field :tracking_events, list_of(:tracking_event) do
      arg :org_id, :integer
      arg :order_id, non_null(:string)
      resolve &TrackingResolver.list_by_order/3
    end

    field :tracking_event, :tracking_event do
      arg :org_id, non_null(:integer)
      arg :tracking_id, non_null(:string)
      resolve &TrackingResolver.get_event/3
    end
  end
end
