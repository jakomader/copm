defmodule Copm.Kafka.AaaConsumer do
  use Broadway

  alias Broadway.Message
  alias Copm.Repo
  alias Copm.Schemas.AuthEvent

  @topic "info.aaa"
  def start_link(_opts) do
    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module:
          {BroadwayKafka.Producer,
          [
            hosts: kafka_hosts(),
            group_id: "copm-aaa-consumer",
            topics: [@topic]
          ]},
        concurrency: 1
      ],
      processors: [default: [concurrency: 2]],
      batchers: [default: [batch_size: 100, batch_timeout: 500, concurrency: 1]]
    )
  end

  @impl true

  def handle_message(_processor, message, _context) do
    message
    |> Message.update_data(&Jason.decode!/1)
  end

  @impl true
  def handle_batch(_batcher, messages, _batch_info, _context) do
    Enum.map(messages, fn %{data: payload} = message ->
      attrs = %{
        user_id: payload["userId"],
        session_id: payload["sessionId"],
        session_ts: parse_dt(payload["sessionTs"]),
        event_type: payload["eventType"],
        ip_address: payload["ipAddress"],
        user_agent: payload["userAgent"],
        device_id: payload["deviceId"],
        geolocation: payload["geolocation"],
        org_id: payload["orgId"]
      }

      AuthEvent.changeset(%AuthEvent{}, attrs)
      |> Repo.insert()
      |> case do
        {:ok, _event} -> message
        {:error, changeset} -> Message.failed(message, inspect(changeset.errors))
      end
    end)
  end

  defp parse_dt(nil), do: nil
  defp parse_dt(dt), do: DateTime.from_iso8601(dt) |> elem(1)

  defp kafka_hosts do
    Application.get_env(:copm, :kafka_hosts, [{"localhost", 9092}])
  end

end
