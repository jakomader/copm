defmodule Copm.Kafka.PaymentConsumer do
  use Broadway

  alias Broadway.Message
  alias Copm.Repo
  alias Copm.Schemas.Payment

  @topic "info.payment"
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
      attrs = %{
        payment_id: payload["paymentId"],
        order_id: payload["orderId"],
        client_id: payload["clientId"],
        user_id: payload["userId"],
        payment_ts: parse_dt(payload["paymentTs"]),
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
        ip_address: payload["ipAddress"]
      }

      Payment.changeset(%Payment{}, attrs)
      |> Repo.insert(on_conflict: {:replace_all_except, [:inserted_at]}, conflict_target: :payment_id)
      |> case do
        {:ok, _payment} -> message
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
