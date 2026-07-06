defmodule Copm.CsvSwallower.Producer do


  @client_id :copm_csv_swallower

  def start_client(hosts \\ kafka_hosts()) do
    case :brod.start_client(hosts, @client_id, []) do
      :ok -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  def publish(topic, key, payload) when is_map(payload) do
    with :ok <- ensure_producer(topic),
         {:ok, json} <- Jason.encode(payload) do
      case :brod.produce_sync(@client_id, topic, :random, to_key(key), json) do
        :ok -> :ok
        {:error, reason} -> {:error, reason}
      end
    end
  end

  defp ensure_producer(topic) do
    case :brod.start_producer(@client_id, topic, []) do
      :ok -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp to_key(nil), do: ""
  defp to_key(key), do: to_string(key)

  defp kafka_hosts do
    Application.get_env(:copm, :kafka_hosts, [{"localhost", 9092}])
  end
end
