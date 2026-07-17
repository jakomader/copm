defmodule Copm.Kafka.UserConsumer do
  use Broadway

  alias Broadway.Message
  alias Copm.Repo
  alias Copm.Schemas.User

  @topic "info.user"

  def start_link(_opts) do
    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module:
          {BroadwayKafka.Producer,
           [
             hosts: kafka_hosts(),
             group_id: "copm-user-consumer",
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
        user_id: payload["userId"],
        client_id: payload["clientId"],
        login: payload["login"],
        person: payload["person"],
        user_starts_at: parse_dt(payload["userStartsAt"]),
        user_ends_at: parse_dt(payload["userEndsAt"]),
        org_id: payload["orgId"]
      }

      User.changeset(%User{}, attrs)
      |> Repo.insert(on_conflict: {:replace_all_except, [:inserted_at]}, conflict_target: [:org_id, :user_id])
      |> case do
        {:ok, _user} -> message
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
