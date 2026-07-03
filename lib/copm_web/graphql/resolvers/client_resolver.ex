defmodule CopmWeb.GraphQL.Resolvers.ClientResolver do
  import Ecto.Query

  alias Copm.Repo
  alias Copm.Schemas.Client

  def get_client(_parent, %{client_id: id}, _ctx) do
    case Repo.get(Client, id) do
      nil -> {:error, "Client #{id} not found"}
      client -> {:ok, client}
    end
  end

  def list_clients(_parent, args, _ctx) do
    query =
      Client
      |> filter_by_inn(args[:inn])
      |> filter_by_status(args[:status])
      |> limit(^args.limit)
      |> offset(^args.offset)

    {:ok, Repo.all(query)}
  end

  defp filter_by_inn(query, nil), do: query
  defp filter_by_inn(query, inn), do: where(query, [arg], arg.inn == ^inn)

  defp filter_by_status(query, nil), do: query
  defp filter_by_status(query, status), do: where(query, [arg], arg.client_status == ^status)

end
