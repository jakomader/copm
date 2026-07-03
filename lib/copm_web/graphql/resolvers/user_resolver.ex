defmodule CopmWeb.GraphQL.Resolvers.UserResolver do
  import Ecto.Query

  alias Copm.Repo
  alias Copm.Schemas.{User, AuthEvent}

  def get_user(_parent, %{user_id: id}, _ctx) do
    case Repo.get(User, id) do
      nil -> {:error, "User #{id} not found"}
      user -> {:ok, user}
    end
  end

  def list_by_client(_parent, %{client_id: client_id}, _ctx) do
    users = User |> where([u], u.client_id == ^client_id) |> Repo.all()
    {:ok, users}
  end

  def list_auth_events(_parent, args, _ctx) do
    query =
      AuthEvent
      |> filter_ae_user(args[:user_id])
      |> filter_ae_session(args[:session_id])
      |> filter_ae_type(args[:event_type])
      |> order_by([e], desc: e.session_ts)
      |> limit(^args.limit)
      |> offset(^args.offset)

    {:ok, Repo.all(query)}
  end

  defp filter_ae_user(q, nil), do: q
  defp filter_ae_user(q, id), do: where(q, [e], e.user_id == ^id)

  defp filter_ae_session(q, nil), do: q
  defp filter_ae_session(q, sid), do: where(q, [e], e.session_id == ^sid)

  defp filter_ae_type(q, nil), do: q
  defp filter_ae_type(q, t), do: where(q, [e], e.event_type == ^t)
end
