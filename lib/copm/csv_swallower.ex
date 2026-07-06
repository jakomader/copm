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
  def ingest(file) do
    case Producer.start_client() do
      :ok ->
        file
        |> Csv.decode()
        |> Enum.map(&Csv.split_by_topic/1)
        |> Enum.reduce(%{ok: 0, error: []}, &handle_row/2)

      {:error, reason} ->
        {:error, {:kafka_client, reason}}
    end
  end

  defp handle_row({:error, reason}, acc) do
    %{acc | error: [{:decode, reason} | acc.error]}
  end

  defp handle_row({:ok, payloads}, acc) do
    Enum.each(payloads, fn {topic, payload} -> publish(topic, payload) end)
    %{acc | ok: acc.ok + 1}
  end

  defp publish(topic, payload) do
    key = Map.get(payload, Map.fetch!(@key_fields, topic))
    Producer.publish(topic, key, payload)
  end
end
