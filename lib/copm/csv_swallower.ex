defmodule Copm.CsvSwallower do
  alias Copm.CsvSwallower.{Csv, Producer}

  @key_fields %{
    "info.cli" => "clientId",
    "info.user" => "userId",
    "info.aaa" => "sessionId",
    "info.order" => "orderId",
    "info.track" => "trackingId",
    "info.payment" => "paymentId",
    "info.msg" => "messageId",
    "info.ipdr" => "sourceIp"
  }
  def key_field(top), do: @key_fields[top]
  def ingest(file, org_id) do
    case Producer.start_client() do
      :ok ->
        file
        |> Csv.decode()
        |> Enum.map(&Csv.split_by_topic/1)
        |> Enum.reduce(%{ok: 0, error: []}, fn row, acc -> handle_row(row, org_id, acc) end)

      {:error, reason} ->
        {:error, {:kafka_client, reason}}
    end
  end

  defp handle_row({:error, reason}, _org_id, acc) do
    %{acc | error: [{:decode, reason} | acc.error]}
  end

  defp handle_row({:ok, payloads}, org_id, acc) do
    Enum.each(payloads, fn {topic, payload} -> publish(topic, payload, org_id) end)
    %{acc | ok: acc.ok + 1}
  end

  defp publish(topic, payload, org_id) do
    payload = Map.put(payload, "orgId", org_id)
    key = Map.get(payload, Map.fetch!(@key_fields, topic))
    Producer.publish(topic, key, payload)
  end
end
