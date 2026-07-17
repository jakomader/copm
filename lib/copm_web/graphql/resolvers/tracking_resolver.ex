defmodule CopmWeb.GraphQL.Resolvers.TrackingResolver do
  import Ecto.Query

  alias Copm.Repo
  alias Copm.Schemas.{TrackingEvent, Order}

  def get_event(_parent, %{org_id: org_id, tracking_id: id}, _ctx) do
    case Repo.get_by(TrackingEvent, org_id: org_id, tracking_id: id) do
      nil -> {:error, "TrackingEvent #{id} not found"}
      event -> {:ok, event}
    end
  end

  def list_by_order(_parent, args, _ctx) do
    events =
      TrackingEvent
      |> where([t], t.order_id == ^args.order_id)
      |> filter_by_org(args[:org_id])
      |> order_by([t], asc: t.event_ts)
      |> Repo.all()

    {:ok, events}
  end

  defp filter_by_org(q, nil), do: q
  defp filter_by_org(q, org_id), do: where(q, [t], t.org_id == ^org_id)

  def scoped_order(%TrackingEvent{} = event, _args, _ctx) do
    {:ok, Repo.get_by(Order, org_id: event.org_id, order_id: event.order_id)}
  end
end
