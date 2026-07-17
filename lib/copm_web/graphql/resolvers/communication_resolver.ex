defmodule CopmWeb.GraphQL.Resolvers.CommunicationResolver do
  import Ecto.Query

  alias Copm.Repo
  alias Copm.Schemas.{Conversation, Client, User, Message, Order}

  def get_conversation(_parent, %{org_id: org_id, conversation_id: id}, _ctx) do
    case Repo.get_by(Conversation, org_id: org_id, conversation_id: id) do
      nil -> {:error, "Conversation #{id} not found"}
      conv -> {:ok, conv}
    end
  end

 def list_conversations(_parent, args, _ctx) do
    query =
      Conversation
      |> filter_org(args[:org_id])
      |> filter_client(args[:client_id])
      |> filter_user(args[:user_id])
      |> filter_channel(args[:channel])
      |> order_by([c], desc: c.starts_at)
      |> limit(^args.limit)
      |> offset(^args.offset)

    {:ok, Repo.all(query)}
  end

  defp filter_org(q, nil), do: q
  defp filter_org(q, org_id), do: where(q, [c], c.org_id == ^org_id)

  defp filter_client(q, nil), do: q
  defp filter_client(q, id), do: where(q, [c], c.client_id == ^id)

  defp filter_user(q, nil), do: q
  defp filter_user(q, id), do: where(q, [c], c.user_id == ^id)

  defp filter_channel(q, nil), do: q
  defp filter_channel(q, ch), do: where(q, [c], c.channel == ^ch)

  def scoped_client(%Conversation{} = conv, _args, _ctx) do
    {:ok, Repo.get_by(Client, org_id: conv.org_id, client_id: conv.client_id)}
  end

  def scoped_user(%Conversation{} = conv, _args, _ctx) do
    {:ok, Repo.get_by(User, org_id: conv.org_id, user_id: conv.user_id)}
  end

  def scoped_messages(%Conversation{} = conv, _args, _ctx) do
    {:ok,
     Repo.all(
       from(m in Message, where: m.org_id == ^conv.org_id and m.conversation_id == ^conv.conversation_id)
     )}
  end

  def scoped_conversation(%Message{} = msg, _args, _ctx) do
    {:ok, Repo.get_by(Conversation, org_id: msg.org_id, conversation_id: msg.conversation_id)}
  end

  def scoped_related_order(%Message{related_order_id: nil}, _args, _ctx), do: {:ok, nil}

  def scoped_related_order(%Message{} = msg, _args, _ctx) do
    {:ok, Repo.get_by(Order, org_id: msg.org_id, order_id: msg.related_order_id)}
  end
end
