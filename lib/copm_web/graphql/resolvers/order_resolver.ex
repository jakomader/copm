defmodule CopmWeb.GraphQL.Resolvers.OrderResolver do
  import Ecto.Query

  alias Copm.Repo
  alias Copm.Schemas.Order

  def get_order(_parent, %{order_id: id}, _ctx) do
    case Repo.get(Order, id) do
      nil -> {:error, "Order #{id} not found"}
      order -> {:ok, order}
    end
  end

  def list_orders(_parent, args, _ctx) do
    query =
      Order
      |> filter_client(args[:client_id])
      |> filter_user(args[:user_id])
      |> filter_status(args[:status])
      |> filter_type(args[:order_type])
      |> order_by([o], desc: o.created_at)
      |> limit(^args.limit)
      |> offset(^args.offset)

    {:ok, Repo.all(query)}
  end

  defp filter_client(q, nil), do: q
  defp filter_client(q, id), do: where(q, [o], o.client_id == ^id)

  defp filter_user(q, nil), do: q
  defp filter_user(q, id), do: where(q, [o], o.user_id == ^id)

  defp filter_status(q, nil), do: q
  defp filter_status(q, s), do: where(q, [o], o.order_status == ^s)

  defp filter_type(q, nil), do: q
  defp filter_type(q, t), do: where(q, [o], o.order_type == ^t)
end
