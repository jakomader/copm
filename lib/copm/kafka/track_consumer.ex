defmodule Copm.Kafka.TrackConsumer do
  use Broadway

  alias Broadway.Message
  alias Copm.Repo
  alias Copm.Schemas.TrackingEvent

  @topic "info.track"

  def start_link(_opts) do
    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module:
          {BroadwayKafka.Producer,
           [
             hosts: kafka_hosts(),
             group_id: "copm-track-consumer",
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
        tracking_id: payload["trackingId"],
        order_id: payload["orderId"],
        event_ts: parse_dt(payload["eventTs"]),
        status_code: payload["statusCode"],
        status_description: payload["statusDescription"],
        location: payload["location"],
        operator_id: payload["operatorId"],
        scanned_device_id: payload["scannedDeviceId"],
        org_id: payload["orgId"]
      }

      TrackingEvent.changeset(%TrackingEvent{}, attrs)
      |> Repo.insert(on_conflict: :nothing, conflict_target: [:org_id, :tracking_id])
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
