defmodule CopmWeb.GraphQL.Resolvers.ClientResolver do
  import Ecto.Query

  alias Copm.Repo
  alias Copm.Schemas.{Client, ClientContact, ClientRelation, User, Order}

  def get_client(_parent, %{org_id: org_id, client_id: id}, _ctx) do
    case Repo.get_by(Client, org_id: org_id, client_id: id) do
      nil -> {:error, "Client #{id} not found"}
      client -> {:ok, client}
    end
  end

  def list_clients(_parent, args, _ctx) do
    query =
      Client
      |> filter_by_org(args[:org_id])
      |> filter_by_inn(args[:inn])
      |> filter_by_status(args[:status])
      |> filter_by_full_name(args[:full_name])
      |> filter_by_phone(args[:phone])
      |> distinct(true)
      |> limit(^args.limit)
      |> offset(^args.offset)

    {:ok, Repo.all(query)}
  end

  defp filter_by_org(query, nil), do: query
  defp filter_by_org(query, org_id), do: where(query, [c], c.org_id == ^org_id)

  defp filter_by_inn(query, nil), do: query
  defp filter_by_inn(query, inn), do: where(query, [c], c.inn == ^inn)

  defp filter_by_status(query, nil), do: query
  defp filter_by_status(query, status), do: where(query, [c], c.client_status == ^status)

  defp filter_by_full_name(query, nil), do: query
  defp filter_by_full_name(query, name), do: where(query, [c], ilike(c.full_name, ^"%#{name}%"))

  defp filter_by_phone(query, nil), do: query

  defp filter_by_phone(query, phone) do
    query
    |> join(:inner, [c], cc in ClientContact,
      on: cc.client_id == c.client_id and cc.org_id == c.org_id
    )
    |> where([c, cc], cc.phone == ^phone)
  end


  def scoped_relations(%Client{} = client, _args, _ctx) do
    {:ok, Repo.all(from(r in ClientRelation, where: r.org_id == ^client.org_id and r.client_id == ^client.client_id))}
  end

  def scoped_contacts(%Client{} = client, _args, _ctx) do
    {:ok, Repo.all(from(c in ClientContact, where: c.org_id == ^client.org_id and c.client_id == ^client.client_id))}
  end

  def scoped_users(%Client{} = client, _args, _ctx) do
    {:ok, Repo.all(from(u in User, where: u.org_id == ^client.org_id and u.client_id == ^client.client_id))}
  end

  def scoped_orders(%Client{} = client, _args, _ctx) do
    {:ok, Repo.all(from(o in Order, where: o.org_id == ^client.org_id and o.client_id == ^client.client_id))}
  end
end
