defmodule CopmWeb.GraphQL.Types.TrackingTypes do
  use Absinthe.Schema.Notation
  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  alias CopmWeb.GraphQL.Resolvers.TrackingResolver

  object :tracking_event do
    field :tracking_id, non_null(:string)
    field :order_id, non_null(:string)
    field :event_ts, non_null(:string)
    field :status_code, non_null(:string)
    field :status_description, :string
    field :location, non_null(:json)
    field :operator_id, :string
    field :scanned_device_id, :string

    field :order, :order, resolve: dataloader(Copm.Repo)
  end

  object :tracking_queries do
    field :tracking_events, list_of(:tracking_event) do
      arg :order_id, non_null(:string)
      resolve &TrackingResolver.list_by_order/3
    end

    field :tracking_event, :tracking_event do
      arg :tracking_id, non_null(:string)
      resolve &TrackingResolver.get_event/3
    end
  end
end
