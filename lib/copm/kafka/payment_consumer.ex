defmodule Copm.Kafka.PaymentConsumer do
  use Broadway

  alias Broadway.Message
  alias Copm.Repo
  alias Copm.Schemas.Payment

  @topic "info.payment"
  @camel_to_snake %{
    "orderId" => "order_id",
    "clientId" => "client_id",
    "userId" => "user_id",
    "paymentTs" => "payment_ts",
    "paymentType" => "payment_type",
    "paymentMethod" => "payment_method",
    "amount" => "amount",
    "currency" => "currency",
    "invoiceNumber" => "invoice_number",
    "paymentStatus" => "payment_status",
    "sessionId" => "session_id",
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
            group_id: "copm-payment-consumer",
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
      case upsert_payment(payload) do
        {:error, changeset} -> Message.failed(message, inspect(changeset.errors))
        _ -> message
      end
    end)
  end

  defp upsert_payment(payload) do
    org_id = payload["orgId"]
    payment_id = payload["paymentId"]

    case Repo.get_by(Payment, org_id: org_id, payment_id: payment_id) do
      nil ->
        attrs = %{
          payment_id: payment_id,
          order_id: payload["orderId"],
          client_id: payload["clientId"],
          user_id: payload["userId"],
          payment_ts: payload["paymentTs"],
          payment_type: payload["paymentType"],
          payment_method: payload["paymentMethod"],
          amount: payload["amount"],
          currency: payload["currency"],
          invoice_number: payload["invoiceNumber"],
          from_bank_info: payload["from"]["bankInfo"],
          to_bank_info: payload["to"]["bankInfo"],
          payment_status: payload["paymentStatus"],
          external_payment_id: payload["externalPaymentId"],
          session_id: payload["sessionId"],
          ip_address: payload["ipAddress"],
          org_id: org_id
        }

        Payment.changeset(%Payment{}, attrs) |> Repo.insert()

      existing ->
        present_fields =
          for {camel_key, snake_key} <- @camel_to_snake,
              not is_nil(payload[camel_key]),
              into: %{} do
            {snake_key, payload[camel_key]}
          end

        present_fields =
          present_fields
          |> maybe_put_nested_bank_info("from_bank_info", payload["from"])
          |> maybe_put_nested_bank_info("to_bank_info", payload["to"])

        existing |> Payment.actualize_changeset(present_fields) |> Repo.update()
    end
  end

  defp maybe_put_nested_bank_info(present_fields, key, nested) when is_map(nested) do
    if is_nil(nested["bankInfo"]) do
      present_fields
    else
      Map.put(present_fields, key, nested["bankInfo"])
    end
  end

  defp maybe_put_nested_bank_info(present_fields, _key, _nested), do: present_fields

  defp kafka_hosts do
    Application.get_env(:copm, :kafka_hosts, [{"localhost", 9092}])
  end
end
