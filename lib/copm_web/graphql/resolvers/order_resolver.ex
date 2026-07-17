defmodule CopmWeb.GraphQL.Resolvers.OrderResolver do
  import Ecto.Query

  alias Copm.Repo
  alias Copm.Schemas.{Order, Client, User, TrackingEvent, Payment}

  def get_order(_parent, %{org_id: org_id, order_id: id}, _ctx) do
    case Repo.get_by(Order, org_id: org_id, order_id: id) do
      nil -> {:error, "Order #{id} not found"}
      order -> {:ok, order}
    end
  end

  def list_orders(_parent, args, _ctx) do
    query =
      Order
      |> filter_org(args[:org_id])
      |> filter_client(args[:client_id])
      |> filter_user(args[:user_id])
      |> filter_status(args[:status])
      |> filter_type(args[:order_type])
      |> order_by([o], desc: o.created_at)
      |> limit(^args.limit)
      |> offset(^args.offset)

    {:ok, Repo.all(query)}
  end

  defp filter_org(q, nil), do: q
  defp filter_org(q, org_id), do: where(q, [o], o.org_id == ^org_id)

  defp filter_client(q, nil), do: q
  defp filter_client(q, id), do: where(q, [o], o.client_id == ^id)

  defp filter_user(q, nil), do: q
  defp filter_user(q, id), do: where(q, [o], o.user_id == ^id)

  defp filter_status(q, nil), do: q
  defp filter_status(q, s), do: where(q, [o], o.order_status == ^s)

  defp filter_type(q, nil), do: q
  defp filter_type(q, t), do: where(q, [o], o.order_type == ^t)

  def scoped_client(%Order{} = order, _args, _ctx) do
    {:ok, Repo.get_by(Client, org_id: order.org_id, client_id: order.client_id)}
  end

  def scoped_user(%Order{} = order, _args, _ctx) do
    {:ok, Repo.get_by(User, org_id: order.org_id, user_id: order.user_id)}
  end

  def scoped_tracking_events(%Order{} = order, _args, _ctx) do
    {:ok, Repo.all(from(t in TrackingEvent, where: t.org_id == ^order.org_id and t.order_id == ^order.order_id))}
  end

  def scoped_payments(%Order{} = order, _args, _ctx) do
    {:ok, Repo.all(from(p in Payment, where: p.org_id == ^order.org_id and p.order_id == ^order.order_id))}
  end
end
