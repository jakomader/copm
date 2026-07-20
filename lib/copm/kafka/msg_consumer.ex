defmodule Copm.Kafka.MsgConsumer do
  use Broadway

  alias Broadway.Message
  alias Copm.Repo
  alias Copm.Schemas.{Conversation, Message}

  @topic "info.msg"

  @conversation_camel_to_snake %{
    "clientId" => "client_id",
    "userId" => "user_id",
    "sessionId" => "session_id",
    "startsAt" => "starts_at",
    "channel" => "channel"
  }

  @message_camel_to_snake %{
    "conversationId" => "conversation_id",
    "messageTs" => "message_ts",
    "messageText" => "message_text",
    "ipAddress" => "ip_address"
  }

  def start_link(_opts) do
    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module:
          {BroadwayKafka.Producer,
          [
            hosts: kafka_hosts(),
            group_id: "copm-msg-consumer",
            topics: [@topic]
          ]},
        concurrency: 1
      ],
      processors: [default: [concurrency: 2]],
      batchers: [default: [batch_size: 50, batch_timeout: 1000, concurrency: 1]]
    )
  end

  @impl true
  def handle_message(_processor, message, _context) do
    message
    |> Broadway.Message.update_data(&Jason.decode!/1)
  end

  @impl true
  def handle_batch(_batcher, messages, _batch_info, _context) do
    Enum.map(messages, fn %{data: payload} = message ->
      case upsert_conversation_and_message(payload) do
        {:error, changeset} -> Broadway.Message.failed(message, inspect(changeset.errors))
        _ -> message
      end
    end)
  end

  defp upsert_conversation_and_message(payload) do
    org_id = payload["orgId"]
    conversation_id = payload["conversationId"]

    conversation_result =
      case Repo.get_by(Conversation, org_id: org_id, conversation_id: conversation_id) do
        nil ->
          attrs = %{
            conversation_id: conversation_id,
            client_id: payload["clientId"],
            user_id: payload["userId"],
            session_id: payload["sessionId"],
            starts_at: payload["startsAt"],
            ends_at: payload["endsAt"],
            channel: payload["channel"],
            org_id: org_id
          }

          Conversation.changeset(%Conversation{}, attrs) |> Repo.insert()

        existing ->
          present_fields =
            for {camel_key, snake_key} <- @conversation_camel_to_snake,
                not is_nil(payload[camel_key]),
                into: %{} do
              {snake_key, payload[camel_key]}
            end

          existing |> Conversation.actualize_changeset(present_fields) |> Repo.update()
      end

    with {:ok, _conversation} <- conversation_result do
      upsert_message(payload, org_id)
    end
  end

  defp upsert_message(payload, org_id) do
    message_id = payload["messageId"]

    case Repo.get_by(Message, org_id: org_id, message_id: message_id) do
      nil ->
        attrs = %{
          message_id: message_id,
          conversation_id: payload["conversationId"],
          message_ts: payload["messageTs"],
          message_text: payload["messageText"],
          attachments: payload["attachments"],
          operator_login: payload["operatorLogin"],
          ip_address: payload["ipAddress"],
          related_order_id: payload["relatedOrderId"],
          org_id: org_id
        }

        Message.changeset(%Message{}, attrs) |> Repo.insert()

      existing ->
        present_fields =
          for {camel_key, snake_key} <- @message_camel_to_snake,
              not is_nil(payload[camel_key]),
              into: %{} do
            {snake_key, payload[camel_key]}
          end

        existing |> Message.actualize_changeset(present_fields) |> Repo.update()
    end
  end

  defp kafka_hosts do
    Application.get_env(:copm, :kafka_hosts, [{"localhost", 9092}])
  end
end
