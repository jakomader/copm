defmodule CopmWeb.GraphQL.Resolvers.OrganizationResolver do
  alias Copm.Organizations

  def list_organizations(_parent, _args, _ctx) do
    {:ok, Organizations.list_organizations()}
  end
end
