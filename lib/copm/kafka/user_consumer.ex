defmodule Copm.Kafka.UserConsumer do
  use Broadway

  alias Broadway.Message
  alias Copm.Repo
  alias Copm.Kafka.Actualize
  alias Copm.Schemas.User

  @topic "info.user"
  @camel_to_snake %{
    "clientId" => "client_id",
    "login" => "login",
    "person" => "person",
    "userStartsAt" => "user_starts_at"
  }
  @known_keys ~w(userId orgId clientId login person userStartsAt userEndsAt _batchId)

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
      result = upsert_user(payload)
      track_batch(payload, result)

      case result do
        {:error, changeset} -> Message.failed(message, inspect(changeset.errors))
        _ -> message
      end
    end)
  end

  defp track_batch(payload, result) do
    case payload["_batchId"] do
      nil ->
        :ok

      batch_id ->
        user_id = payload["userId"]

        case result do
          {:error, changeset} -> Copm.IngestBatches.mark_processed(batch_id, user_id, inspect(changeset.errors))
          _ -> Copm.IngestBatches.mark_processed(batch_id, user_id, nil)
        end
    end
  end

  defp upsert_user(payload) do
    org_id = payload["orgId"]
    user_id = payload["userId"]

    case Repo.get_by(User, org_id: org_id, user_id: user_id) do
      nil ->
        attrs = %{
          user_id: user_id,
          client_id: payload["clientId"],
          login: payload["login"],
          person: payload["person"],
          user_starts_at: payload["userStartsAt"],
          user_ends_at: payload["userEndsAt"],
          org_id: org_id
        }

        User.changeset(%User{}, attrs) |> Repo.insert()

      existing ->
        case Actualize.unknown_fields(payload, @known_keys) do
          [] ->
            present_fields =
              for {camel_key, snake_key} <- @camel_to_snake,
                  not is_nil(payload[camel_key]),
                  into: %{} do
                {snake_key, payload[camel_key]}
              end

            existing |> User.actualize_changeset(present_fields) |> Repo.update()

          extra ->
            Actualize.reject_unknown_fields(existing, extra)
        end
    end
  end

  defp kafka_hosts do
    Application.get_env(:copm, :kafka_hosts, [{"localhost", 9092}])
  end
end
