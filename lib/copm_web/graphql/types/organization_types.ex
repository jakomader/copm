defmodule CopmWeb.GraphQL.Types.OrganizationTypes do
  use Absinthe.Schema.Notation

  alias CopmWeb.GraphQL.Resolvers.OrganizationResolver

  object :organization do
    field :id, non_null(:integer)
    field :org_name, non_null(:string)
  end

  object :organization_queries do
    field :organizations, list_of(:organization) do
      resolve &OrganizationResolver.list_organizations/3
    end
  end
end
