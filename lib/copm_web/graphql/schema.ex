defmodule CopmWeb.GraphQL.Schema do
  use Absinthe.Schema

  import_types Absinthe.Type.Custom
  import_types CopmWeb.GraphQL.Types.ClientTypes
  import_types CopmWeb.GraphQL.Types.UserTypes
  import_types CopmWeb.GraphQL.Types.OrderTypes
  import_types CopmWeb.GraphQL.Types.TrackingTypes
  import_types CopmWeb.GraphQL.Types.PaymentTypes
  import_types CopmWeb.GraphQL.Types.CommunicationTypes
  import_types CopmWeb.GraphQL.Types.IpdrTypes
  #json scalar for map fields
  scalar :json do
    description "Arbitrary JSON"
    parse &parse_json/1
    serialize &Jason.encode!/1
  end

  query do
    import_fields :client_queries
    import_fields :user_queries
    import_fields :order_queries
    import_fields :tracking_queries
    import_fields :payment_queries
    import_fields :communication_queries
    import_fields :ipdr_queries
  end
  def context(ctx) do
    loader =
      Dataloader.new()
      |> Dataloader.add_source(Copm.Repo, Dataloader.Ecto.new(Copm.Repo))

    Map.put(ctx, :loader, loader)
  end

  def plugins do
    [Absinthe.Middleware.Dataloader | Absinthe.Plugin.defaults()]
  end

  defp parse_json(%Absinthe.Blueprint.Input.String{value: value}) do
    case Jason.decode(value) do
      {:ok, result} -> {:ok, result}
      _ -> :error
    end
  end

  defp parse_json(%Absinthe.Blueprint.Input.Null{}), do: {:ok, nil}
  defp parse_json(_), do: :error
end
