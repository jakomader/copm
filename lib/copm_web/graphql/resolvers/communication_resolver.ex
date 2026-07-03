defmodule CopmWeb.GraphQL.Resolvers.CommunicationResolver do
  import Ecto.Query

  alias Copm.Repo
  alias Copm.Schemas.Conversation

  def get_conversation(_parent, %{conversation_id: id}, _ctx) do
    case Repo.get(Conversation, id) do
      nil -> {:error, "Conversation #{id} not found"}
      conv -> {:ok, conv}
    end
  end

 def list_conversations(_parent, args, _ctx) do
    query =
      Conversation
      |> filter_client(args[:client_id])
      |> filter_user(args[:user_id])
      |> filter_channel(args[:channel])
      |> order_by([c], desc: c.starts_at)
      |> limit(^args.limit)
      |> offset(^args.offset)

    {:ok, Repo.all(query)}
  end

  defp filter_client(q, nil), do: q
  defp filter_client(q, id), do: where(q, [c], c.client_id == ^id)

  defp filter_user(q, nil), do: q
  defp filter_user(q, id), do: where(q, [c], c.user_id == ^id)

  defp filter_channel(q, nil), do: q
  defp filter_channel(q, ch), do: where(q, [c], c.channel == ^ch)
end
