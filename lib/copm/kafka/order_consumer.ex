defmodule Copm.Kafka.OrderConsumer do
  use Broadway

  alias Broadway.Message
  alias Copm.Repo
  alias Copm.Schemas.Order

  @topic "info.order"

  def start_link(_opts) do
    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module:
          {BroadwayKafka.Producer,
           [
             hosts: kafka_hosts(),
             group_id: "copm-order-consumer",
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
    |> Message.update_data(&Jason.decode!/1)
  end

  @impl true

  def handle_batch(_batcher, messages, _batch_info, _context) do
    Enum.map(messages, fn %{data: payload} = message ->
      attrs = %{
        order_id: payload["orderId"],
        contract_id: payload["contractId"],
        client_id: payload["clientId"],
        user_id: payload["userId"],
        order_status: payload["orderStatus"],
        order_type: payload["orderType"],
        created_at: parse_dt(payload["createdAt"]),
        confirmed_at: parse_dt(payload["confirmedAt"]),
        sender: payload["sender"],
        receiver: payload["receiver"],
        route_from: payload["routeFrom"],
        route_to: payload["routeTo"],
        transit_points: payload["transitPoints"],
        carrier: payload["carrier"],
        flight_number: payload["flightNumber"],
        vehicle_number: payload["vehicleNumber"],
        awb_number: payload["awbNumber"],
        cmr_number: payload["cmrNumber"],
        cargo_description: payload["cargoDescription"],
        cargo_weight: payload["cargoWeight"],
        cargo_volume: payload["cargoVolume"],
        cargo_danger_class: payload["cargoDangerClass"],
        cargo_special_conditions: payload["cargoSpecialConditions"],
        insurance_info: payload["insuranceInfo"],
        customs_info: payload["customsInfo"],
        estimated_delivery_date: parse_date(payload["estimatedDeliveryDate"]),
        actual_delivery_date: parse_date(payload["actualDeliveryDate"]),
        org_id: payload["orgId"]
      }

      Order.changeset(%Order{}, attrs)
      |> Repo.insert(on_conflict: {:replace_all_except, [:inserted_at]}, conflict_target: [:org_id, :order_id])
      |> case do
        {:ok, _order} -> message
        {:error, changeset} -> Message.failed(message, inspect(changeset.errors))
      end
    end)
  end

  defp parse_dt(nil), do: nil
  defp parse_dt(dt), do: DateTime.from_iso8601(dt) |> elem(1)

  defp parse_date(nil), do: nil
  defp parse_date(d), do: Date.from_iso8601!(d)

  defp kafka_hosts do
    Application.get_env(:copm, :kafka_hosts, [{"localhost", 9092}])
  end

end
