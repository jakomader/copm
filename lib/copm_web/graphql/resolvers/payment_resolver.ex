defmodule CopmWeb.GraphQL.Resolvers.PaymentResolver do
  import Ecto.Query

  alias Copm.Repo
  alias Copm.Schemas.Payment

  def get_payment(_parent, %{payment_id: id}, _ctx) do
    case Repo.get(Payment, id) do
      nil -> {:error, "Payment #{id} not found"}
      payment -> {:ok, payment}
    end
  end

  def list_payments(_parent, args, _ctx) do
    query =
      Payment
      |> filter_order(args[:order_id])
      |> filter_client(args[:client_id])
      |> filter_status(args[:status])
      |> order_by([p], desc: p.payment_ts)
      |> limit(^args.limit)
      |> offset(^args.offset)

    {:ok, Repo.all(query)}
  end

  defp filter_order(q, nil), do: q
  defp filter_order(q, id), do: where(q, [p], p.order_id == ^id)

  defp filter_client(q, nil), do: q
  defp filter_client(q, id), do: where(q, [p], p.client_id == ^id)

  defp filter_status(q, nil), do: q
  defp filter_status(q, s), do: where(q, [p], p.payment_status == ^s)
end
