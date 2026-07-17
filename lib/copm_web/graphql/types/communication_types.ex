defmodule CopmWeb.GraphQL.Types.CommunicationTypes do
  use Absinthe.Schema.Notation

  alias CopmWeb.GraphQL.Resolvers.CommunicationResolver

  object :conversation do
    field :conversation_id, non_null(:string)
    field :org_id, non_null(:integer)
    field :client_id, non_null(:string)
    field :user_id, non_null(:string)
    field :session_id, non_null(:string)
    field :starts_at, non_null(:string)
    field :ends_at, :string
    field :channel, non_null(:string)

    field :client, :client, resolve: &CommunicationResolver.scoped_client/3
    field :user, :user, resolve: &CommunicationResolver.scoped_user/3
    field :messages, list_of(:message), resolve: &CommunicationResolver.scoped_messages/3
  end

  object :message do
    field :message_id, non_null(:string)
    field :org_id, non_null(:integer)
    field :conversation_id, non_null(:string)
    field :message_ts, non_null(:string)
    field :message_text, non_null(:string)
    field :attachments, list_of(:string)
    field :operator_login, :string
    field :ip_address, non_null(:string)
    field :related_order_id, :string

    field :conversation, :conversation, resolve: &CommunicationResolver.scoped_conversation/3
    field :related_order, :order, resolve: &CommunicationResolver.scoped_related_order/3
  end

  object :communication_queries do
    field :conversation, :conversation do
      arg :org_id, non_null(:integer)
      arg :conversation_id, non_null(:string)
      resolve &CommunicationResolver.get_conversation/3
    end

    field :conversations, list_of(:conversation) do
      arg :org_id, :integer
      arg :client_id, :string
      arg :user_id, :string
      arg :channel, :string
      arg :limit, :integer, default_value: 20
      arg :offset, :integer, default_value: 0
      resolve &CommunicationResolver.list_conversations/3
    end
  end
end
