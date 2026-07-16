defmodule CopmWeb.GraphQL.Types.SessionTypes do
  use Absinthe.Schema.Notation
  alias CopmWeb.GraphQL.Resolvers.SessionResolver
  object :operator do
    field :id, non_null(:id)
    field :login, non_null(:string)
    field :name, non_null(:string)
    field :status, non_null(:string)
    field :purpose, :string
    field :role, non_null(:string)
  end

  object :session_payload do
    field :token, non_null(:string)
    field :refresh_token, non_null(:string)
    field :expires_in, non_null(:integer)

    field :operator, :operator
  end

  object :session_mutations do
    field :session_create, :session_payload do
      arg :login, non_null(:string)
      arg :password, non_null(:string)
      resolve &SessionResolver.session_create/3

    end
    field :session_refresh, :session_payload do
      arg :refresh_token, non_null(:string)
      resolve &SessionResolver.session_refresh/3
    end
  end
  object :user_mutations do
    field :user_create, :operator do
      arg :login, non_null(:string)
      arg :password, non_null(:string)
      arg :name, non_null(:string)
      arg :status, :string
      arg :purpose, :string
      arg :role, non_null(:string)
      resolve &SessionResolver.user_create/3
    end
    field :user_update, :operator do
      arg :operator_id, non_null(:id)
      arg :login, :string
      arg :name, :string
      arg :status, :string
      arg :purpose, :string
      arg :role, :string
      resolve &SessionResolver.user_update/3
    end
    field :user_delete, :operator do
      arg :operator_id, non_null(:id)
      resolve &SessionResolver.user_delete/3
    end
    field :user_block, :operator do
      arg :operator_id, non_null(:id)
      resolve &SessionResolver.user_block/3
    end
  end
end
