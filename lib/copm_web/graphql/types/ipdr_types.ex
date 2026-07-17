defmodule CopmWeb.GraphQL.Types.IpdrTypes do
  use Absinthe.Schema.Notation

  alias CopmWeb.GraphQL.Resolvers.IpdrResolver

  object :ipdr_record do
    field :id, non_null(:id)
    field :org_id, non_null(:integer)
    field :ts, non_null(:string)
    field :source_ip, non_null(:string)
    field :source_port, non_null(:integer)
    field :destination_ip, non_null(:string)
    field :destination_port, non_null(:integer)
    field :protocol, non_null(:string)
    field :flag, :string
    field :bytes_transferred, non_null(:integer)
  end

  object :ipdr_queries do
    field :ipdr_records, list_of(:ipdr_record) do
      arg :org_id, :integer
      arg :source_ip, :string
      arg :from_ts, :string
      arg :to_ts, :string
      arg :limit, :integer, default_value: 100
      arg :offset, :integer, default_value: 0
      resolve &IpdrResolver.list_records/3
    end
  end
end
