defmodule CopmWeb.GraphQL.Types.UserTypes do
  use Absinthe.Schema.Notation

  alias CopmWeb.GraphQL.Resolvers.UserResolver

  object :user do
    field :user_id, non_null(:string)
    field :org_id, non_null(:integer)
    field :client_id, non_null(:string)
    field :login, non_null(:string)
    field :person, non_null(:json)
    field :user_starts_at, non_null(:string)
    field :user_ends_at, :string

    field :client, :client, resolve: &UserResolver.scoped_client/3
    field :auth_events, list_of(:auth_event), resolve: &UserResolver.scoped_auth_events/3
    field :orders, list_of(:order), resolve: &UserResolver.scoped_orders/3
  end

  object :auth_event do
    field :id, non_null(:id)
    field :org_id, non_null(:integer)
    field :user_id, non_null(:string)
    field :session_id, non_null(:string)
    field :session_ts, non_null(:string)
    field :event_type, non_null(:string)
    field :ip_address, non_null(:json)
    field :user_agent, non_null(:string)
    field :device_id, :string
    field :geolocation, :string

    field :user, :user, resolve: &UserResolver.scoped_user/3
  end

  object :user_queries do
    field :user, :user do
      arg :org_id, non_null(:integer)
      arg :user_id, non_null(:string)
      resolve &UserResolver.get_user/3
    end

    field :users_by_client, list_of(:user) do
      arg :org_id, :integer
      arg :client_id, non_null(:string)
      resolve &UserResolver.list_by_client/3
    end

    field :auth_events, list_of(:auth_event) do
      arg :org_id, :integer
      arg :user_id, :string
      arg :session_id, :string
      arg :event_type, :string
      arg :limit, :integer, default_value: 50
      arg :offset, :integer, default_value: 0
      resolve &UserResolver.list_auth_events/3
    end
  end
end
