defmodule Copm.Kafka.UserConsumer do
  use Broadway

  alias Broadway.Message
  alias Copm.Repo
  alias Copm.Schemas.User

  @topic "info.user"
  @camel_to_snake %{
    "clientId" => "client_id",
    "login" => "login",
    "person" => "person",
    "userStartsAt" => "user_starts_at"
  }

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
      case upsert_user(payload) do
        {:error, changeset} -> Message.failed(message, inspect(changeset.errors))
        _ -> message
      end
    end)
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
        present_fields =
          for {camel_key, snake_key} <- @camel_to_snake,
              not is_nil(payload[camel_key]),
              into: %{} do
            {snake_key, payload[camel_key]}
          end

        existing |> User.actualize_changeset(present_fields) |> Repo.update()
    end
  end

  defp kafka_hosts do
    Application.get_env(:copm, :kafka_hosts, [{"localhost", 9092}])
  end
end
