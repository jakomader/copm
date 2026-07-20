defmodule Copm.Kafka.OrderConsumer do
  use Broadway

  alias Broadway.Message
  alias Copm.Repo
  alias Copm.Schemas.Order

  @topic "info.order"
  @camel_to_snake %{
    "contractId" => "contract_id",
    "clientId" => "client_id",
    "userId" => "user_id",
    "orderStatus" => "order_status",
    "orderType" => "order_type",
    "createdAt" => "created_at",
    "confirmedAt" => "confirmed_at",
    "sender" => "sender",
    "receiver" => "receiver",
    "routeFrom" => "route_from",
    "routeTo" => "route_to",
    "carrier" => "carrier",
    "cargoDescription" => "cargo_description",
    "cargoWeight" => "cargo_weight",
    "estimatedDeliveryDate" => "estimated_delivery_date",
    "actualDeliveryDate" => "actual_delivery_date"
  }

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
      case upsert_order(payload) do
        {:error, changeset} -> Message.failed(message, inspect(changeset.errors))
        _ -> message
      end
    end)
  end

  defp upsert_order(payload) do
    org_id = payload["orgId"]
    order_id = payload["orderId"]

    case Repo.get_by(Order, org_id: org_id, order_id: order_id) do
      nil ->
        attrs = %{
          order_id: order_id,
          contract_id: payload["contractId"],
          client_id: payload["clientId"],
          user_id: payload["userId"],
          order_status: payload["orderStatus"],
          order_type: payload["orderType"],
          created_at: payload["createdAt"],
          confirmed_at: payload["confirmedAt"],
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
          estimated_delivery_date: payload["estimatedDeliveryDate"],
          actual_delivery_date: payload["actualDeliveryDate"],
          org_id: org_id
        }

        Order.changeset(%Order{}, attrs) |> Repo.insert()

      existing ->
        present_fields =
          for {camel_key, snake_key} <- @camel_to_snake,
              not is_nil(payload[camel_key]),
              into: %{} do
            {snake_key, payload[camel_key]}
          end

        existing |> Order.actualize_changeset(present_fields) |> Repo.update()
    end
  end

  defp kafka_hosts do
    Application.get_env(:copm, :kafka_hosts, [{"localhost", 9092}])
  end
end
