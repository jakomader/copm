defmodule CopmWeb.GraphQL.Resolvers.UserResolver do
  import Ecto.Query

  alias Copm.Repo
  alias Copm.Schemas.{User, AuthEvent, Client, Order}

  def get_user(_parent, %{org_id: org_id, user_id: id}, _ctx) do
    case Repo.get_by(User, org_id: org_id, user_id: id) do
      nil -> {:error, "User #{id} not found"}
      user -> {:ok, user}
    end
  end

  def list_by_client(_parent, args, _ctx) do
    users =
      User
      |> where([u], u.client_id == ^args.client_id)
      |> filter_by_org(args[:org_id])
      |> Repo.all()

    {:ok, users}
  end

  defp filter_by_org(q, nil), do: q
  defp filter_by_org(q, org_id), do: where(q, [u], u.org_id == ^org_id)

  def list_auth_events(_parent, args, _ctx) do
    query =
      AuthEvent
      |> filter_ae_org(args[:org_id])
      |> filter_ae_user(args[:user_id])
      |> filter_ae_session(args[:session_id])
      |> filter_ae_type(args[:event_type])
      |> order_by([e], desc: e.session_ts)
      |> limit(^args.limit)
      |> offset(^args.offset)

    {:ok, Repo.all(query)}
  end

  defp filter_ae_org(q, nil), do: q
  defp filter_ae_org(q, org_id), do: where(q, [e], e.org_id == ^org_id)

  defp filter_ae_user(q, nil), do: q
  defp filter_ae_user(q, id), do: where(q, [e], e.user_id == ^id)

  defp filter_ae_session(q, nil), do: q
  defp filter_ae_session(q, sid), do: where(q, [e], e.session_id == ^sid)

  defp filter_ae_type(q, nil), do: q
  defp filter_ae_type(q, t), do: where(q, [e], e.event_type == ^t)

  def scoped_client(%User{} = user, _args, _ctx) do
    {:ok, Repo.get_by(Client, org_id: user.org_id, client_id: user.client_id)}
  end

  def scoped_auth_events(%User{} = user, _args, _ctx) do
    {:ok, Repo.all(from(e in AuthEvent, where: e.org_id == ^user.org_id and e.user_id == ^user.user_id))}
  end


  def scoped_orders(%User{} = user, _args, _ctx) do
    {:ok, Repo.all(from(o in Order, where: o.org_id == ^user.org_id and o.user_id == ^user.user_id))}
  end

  def scoped_user(%AuthEvent{} = event, _args, _ctx) do
    {:ok, Repo.get_by(User, org_id: event.org_id, user_id: event.user_id)}
  end
end
