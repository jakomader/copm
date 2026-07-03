defmodule CopmWeb.GraphQL.Resolvers.TrackingResolver do
  import Ecto.Query

  alias Copm.Repo
  alias Copm.Schemas.TrackingEvent

  def get_event(_parent, %{tracking_id: id}, _ctx) do
    case Repo.get(TrackingEvent, id) do
      nil -> {:error, "TrackingEvent #{id} not found"}
      event -> {:ok, event}
    end
  end

  def list_by_order(_parent, %{order_id: order_id}, _ctx) do
    events =
      TrackingEvent
      |> where([t], t.order_id == ^order_id)
      |> order_by([t], asc: t.event_ts)
      |> Repo.all()

    {:ok, events}
  end
end
