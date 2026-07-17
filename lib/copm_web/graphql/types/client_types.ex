defmodule CopmWeb.GraphQL.Types.ClientTypes do
  use Absinthe.Schema.Notation

  alias CopmWeb.GraphQL.Resolvers.ClientResolver

  object :client do
    field :client_id, non_null(:string)
    field :org_id, non_null(:integer)
    field :client_status, non_null(:string)
    field :registration_date, non_null(:string)
    field :full_name, non_null(:string)
    field :short_name, :string
    field :inn, non_null(:string)
    field :kpp, :string
    field :ogrn, non_null(:string)
    field :okpo, :string
    field :tax_agency_code, :string
    field :legal_address, non_null(:json)
    field :postal_address, :json
    field :reg_country_code, non_null(:string)
    field :is_foreign, non_null(:boolean)
    field :economic_sector, :string
    field :bank_info, non_null(:json)

    field :relations, list_of(:client_relation), resolve: &ClientResolver.scoped_relations/3
    field :contacts, list_of(:client_contact), resolve: &ClientResolver.scoped_contacts/3
    field :users, list_of(:user), resolve: &ClientResolver.scoped_users/3
    field :orders, list_of(:order), resolve: &ClientResolver.scoped_orders/3
  end

  object :client_relation do
    field :id, non_null(:id)
    field :client_id, non_null(:string)
    field :full_name, non_null(:string)
    field :inn, non_null(:string)
    field :position, non_null(:string)
    field :role, non_null(:string)
    field :date_begin, :string
    field :date_end, :string
  end

  object :client_contact do
    field :id, non_null(:id)
    field :client_id, non_null(:string)
    field :phone, non_null(:string)
    field :email, non_null(:string)
  end

  object :client_queries do
    field :client, :client do
      arg :org_id, non_null(:integer)
      arg :client_id, non_null(:string)
      resolve &ClientResolver.get_client/3
    end

    field :clients, list_of(:client) do
      arg :org_id, :integer
      arg :inn, :string
      arg :status, :string
      arg :full_name, :string
      arg :phone, :string
      arg :limit, :integer, default_value: 20
      arg :offset, :integer, default_value: 0
      resolve &ClientResolver.list_clients/3
    end
  end
end
