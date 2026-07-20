defmodule Copm.Kafka.TrackConsumer do
  use Broadway

  alias Broadway.Message
  alias Copm.Repo
  alias Copm.Schemas.TrackingEvent

  @topic "info.track"
  @camel_to_snake %{
    "orderId" => "order_id",
    "eventTs" => "event_ts",
    "statusCode" => "status_code",
    "location" => "location"
  }

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
      case upsert_tracking_event(payload) do
        {:error, changeset} -> Message.failed(message, inspect(changeset.errors))
        _ -> message
      end
    end)
  end

  defp upsert_tracking_event(payload) do
    org_id = payload["orgId"]
    tracking_id = payload["trackingId"]

    case Repo.get_by(TrackingEvent, org_id: org_id, tracking_id: tracking_id) do
      nil ->
        attrs = %{
          tracking_id: tracking_id,
          order_id: payload["orderId"],
          event_ts: payload["eventTs"],
          status_code: payload["statusCode"],
          status_description: payload["statusDescription"],
          location: payload["location"],
          operator_id: payload["operatorId"],
          scanned_device_id: payload["scannedDeviceId"],
          org_id: org_id
        }

        TrackingEvent.changeset(%TrackingEvent{}, attrs) |> Repo.insert()

      existing ->
        present_fields =
          for {camel_key, snake_key} <- @camel_to_snake,
              not is_nil(payload[camel_key]),
              into: %{} do
            {snake_key, payload[camel_key]}
          end

        existing |> TrackingEvent.actualize_changeset(present_fields) |> Repo.update()
    end
  end

  defp kafka_hosts do
    Application.get_env(:copm, :kafka_hosts, [{"localhost", 9092}])
  end
end
