defmodule CopmWeb.GraphQL.Resolvers.PaymentResolver do
  import Ecto.Query

  alias Copm.Repo
  alias Copm.Schemas.{Payment, Order, Client, User}

  def get_payment(_parent, %{org_id: org_id, payment_id: id}, _ctx) do
    case Repo.get_by(Payment, org_id: org_id, payment_id: id) do
      nil -> {:error, "Payment #{id} not found"}
      payment -> {:ok, payment}
    end
  end

  def list_payments(_parent, args, _ctx) do
    query =
      Payment
      |> filter_org(args[:org_id])
      |> filter_order(args[:order_id])
      |> filter_client(args[:client_id])
      |> filter_status(args[:status])
      |> order_by([p], desc: p.payment_ts)
      |> limit(^args.limit)
      |> offset(^args.offset)

    {:ok, Repo.all(query)}
  end

  defp filter_org(q, nil), do: q
  defp filter_org(q, org_id), do: where(q, [p], p.org_id == ^org_id)

  defp filter_order(q, nil), do: q
  defp filter_order(q, id), do: where(q, [p], p.order_id == ^id)

  defp filter_client(q, nil), do: q
  defp filter_client(q, id), do: where(q, [p], p.client_id == ^id)

  defp filter_status(q, nil), do: q
  defp filter_status(q, s), do: where(q, [p], p.payment_status == ^s)

  def scoped_order(%Payment{} = payment, _args, _ctx) do
    {:ok, Repo.get_by(Order, org_id: payment.org_id, order_id: payment.order_id)}
  end

  def scoped_client(%Payment{} = payment, _args, _ctx) do
    {:ok, Repo.get_by(Client, org_id: payment.org_id, client_id: payment.client_id)}
  end

  def scoped_user(%Payment{} = payment, _args, _ctx) do
    {:ok, Repo.get_by(User, org_id: payment.org_id, user_id: payment.user_id)}
  end
end
