defmodule Copm.Kafka.MsgConsumer do
  use Broadway

  alias Broadway.Message
  alias Copm.Repo
  alias Copm.Schemas.{Conversation, Message}

  @topic "info.msg"
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
      conversation_attrs = %{
        conversation_id: payload["conversationId"],
        client_id: payload["clientId"],
        user_id: payload["userId"],
        session_id: payload["sessionId"],
        starts_at: parse_dt(payload["startsAt"]),
        ends_at: parse_dt(payload["endsAt"]),
        channel: payload["channel"],
        org_id: payload["orgId"]
      }

      conversation_result =
        Conversation.changeset(%Conversation{}, conversation_attrs)
        |> Repo.insert(
          on_conflict: {:replace_all_except, [:inserted_at]},
          conflict_target: [:org_id, :conversation_id]
        )

      case conversation_result do
        {:error, changeset} ->
          Broadway.Message.failed(message, inspect(changeset.errors))

        {:ok, _conversation} ->
          msg_attrs = %{
            message_id: payload["messageId"],
            conversation_id: payload["conversationId"],
            message_ts: parse_dt(payload["messageTs"]),
            message_text: payload["messageText"],
            attachments: payload["attachments"],
            operator_login: payload["operatorLogin"],
            ip_address: payload["ipAddress"],
            related_order_id: payload["relatedOrderId"],
            org_id: payload["orgId"]
          }

          Message.changeset(%Message{}, msg_attrs)
          |> Repo.insert(on_conflict: :nothing, conflict_target: [:org_id, :message_id])
          |> case do
            {:ok, _msg} -> message
            {:error, changeset} -> Broadway.Message.failed(message, inspect(changeset.errors))
          end
      end
    end)
  end

  defp parse_dt(nil), do: nil
  defp parse_dt(dt), do: DateTime.from_iso8601(dt) |> elem(1)

  defp kafka_hosts do
    Application.get_env(:copm, :kafka_hosts, [{"localhost", 9092}])
  end
end
