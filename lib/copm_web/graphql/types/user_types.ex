defmodule CopmWeb.GraphQL.Types.UserTypes do
  use Absinthe.Schema.Notation
  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  alias CopmWeb.GraphQL.Resolvers.UserResolver

  object :user do
    field :user_id, non_null(:string)
    field :client_id, non_null(:string)
    field :login, non_null(:string)
    field :person, non_null(:json)
    field :user_starts_at, non_null(:string)
    field :user_ends_at, :string

    field :client, :client, resolve: dataloader(Copm.Repo)
    field :auth_events, list_of(:auth_event), resolve: dataloader(Copm.Repo)
    field :orders, list_of(:order), resolve: dataloader(Copm.Repo)
  end

  object :auth_event do
    field :id, non_null(:id)
    field :user_id, non_null(:string)
    field :session_id, non_null(:string)
    field :session_ts, non_null(:string)
    field :event_type, non_null(:string)
    field :ip_address, non_null(:json)
    field :user_agent, non_null(:string)
    field :device_id, :string
    field :geolocation, :string

    field :user, :user, resolve: dataloader(Copm.Repo)
  end

  object :user_queries do
    field :user, :user do
      arg :user_id, non_null(:string)
      resolve &UserResolver.get_user/3
    end

    field :users_by_client, list_of(:user) do
      arg :client_id, non_null(:string)
      resolve &UserResolver.list_by_client/3
    end

    field :auth_events, list_of(:auth_event) do
      arg :user_id, :string
      arg :session_id, :string
      arg :event_type, :string
      arg :limit, :integer, default_value: 50
      arg :offset, :integer, default_value: 0
      resolve &UserResolver.list_auth_events/3
    end
  end
end
