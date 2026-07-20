defmodule Copm.Kafka.IpdrConsumer do
  use Broadway

  alias Broadway.Message
  alias Copm.Repo
  alias Copm.Schemas.IpdrRecord

  @topic "info.ipdr"
  def start_link(_opts) do
    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module:
          {BroadwayKafka.Producer,
          [
            hosts: kafka_hosts(),
            group_id: "copm-ipdr-consumer",
            topics: [@topic]
          ]},
        concurrency: 1
      ],
      processors: [default: [concurrency: 4]],
      batchers: [default: [batch_size: 200, batch_timeout: 500, concurrency: 2]]
    )
  end

  @impl true
  def handle_message(_processor, message, _context) do
    message
    |> Message.update_data(&Jason.decode!/1)
  end

  @impl true
  def handle_batch(_batcher, messages, _batch_info, _context) do
    records =
      Enum.map(messages, fn %{data: payload} ->
        %{
          ts: payload["ts"],
          source_ip: payload["sourceIp"],
          source_port: parse_int(payload["sourcePort"]),
          destination_ip: payload["destinationIp"],
          destination_port: parse_int(payload["destinationPort"]),
          protocol: payload["protocol"],
          flag: payload["flag"],
          bytes_transferred: parse_int(payload["bytesTransferred"]),
          org_id: payload["orgId"],
          inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
          updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
        }
      end)

    Repo.insert_all(IpdrRecord, records, on_conflict: :nothing)
    messages
  end

  defp parse_int(nil), do: nil
  defp parse_int(value) when is_integer(value), do: value
  defp parse_int(value) when is_binary(value), do: String.to_integer(value)

  defp kafka_hosts do
    Application.get_env(:copm, :kafka_hosts, [{"localhost", 9092}])
  end

end
