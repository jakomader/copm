defmodule Copm.Kafka.CliConsumer do
  use Broadway

  alias Broadway.Message
  alias Copm.Repo
  alias Copm.Schemas.{Client, ClientRelation, ClientContact}

  @topic "info.cli"
  @camel_to_snake %{
    "clientStatus" => "client_status",
    "registrationDate" => "registration_date",
    "fullName" => "full_name",
    "inn" => "inn",
    "ogrn" => "ogrn",
    "ogrnip" => "ogrn",
    "legalAddress" => "legal_address",
    "regCountryCode" => "reg_country_code",
    "isForeign" => "is_foreign",
    "bankInfo" => "bank_info"
  }

  @relation_camel_to_snake %{
    "fullName" => "full_name",
    "position" => "position",
    "role" => "role"
  }

  @contact_camel_to_snake %{
    "email" => "email"
  }

  def start_link(_opts) do
    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module:
          {BroadwayKafka.Producer, [
            hosts: kafka_hosts(),
            group_id: "copm-cli-consumer",
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
      case upsert_client(payload) do
        {:error, changeset} -> Message.failed(message, inspect(changeset.errors))
        _ -> message
      end
    end)
  end

  defp upsert_client(payload) do
    org_id = payload["orgId"]
    client_id = payload["clientId"]

    client_result =
      case Repo.get_by(Client, org_id: org_id, client_id: client_id) do
        nil ->
          client_attrs = %{
            client_id: client_id,
            client_status: payload["clientStatus"],
            registration_date: payload["registrationDate"],
            full_name: payload["fullName"],
            short_name: payload["shortName"],
            inn: payload["inn"],
            kpp: payload["kpp"],
            ogrn: payload["ogrn"] || payload["ogrnip"],
            okpo: payload["okpo"],
            tax_agency_code: payload["taxAgencyCode"],
            legal_address: payload["legalAddress"],
            postal_address: payload["postalAddress"],
            reg_country_code: payload["regCountryCode"],
            is_foreign: payload["isForeign"] || false,
            economic_sector: payload["economicSector"],
            bank_info: payload["bankInfo"],
            org_id: org_id
          }

          Client.changeset(%Client{}, client_attrs) |> Repo.insert()

        existing ->
          present_fields =
            for {camel_key, snake_key} <- @camel_to_snake,
                not is_nil(payload[camel_key]),
                into: %{} do
              {snake_key, payload[camel_key]}
            end

          existing |> Client.actualize_changeset(present_fields) |> Repo.update()
      end

    with {:ok, _client} <- client_result,
         :ok <- upsert_relations(payload["relations"] || [], org_id, client_id),
         :ok <- upsert_contacts(payload["contacts"] || [], org_id, client_id) do
      client_result
    end
  end

  defp upsert_relations(relations, org_id, client_id) do
    Enum.reduce_while(relations, :ok, fn rel, :ok ->
      case upsert_relation(rel, org_id, client_id) do
        {:ok, _} -> {:cont, :ok}
        {:error, _} = error -> {:halt, error}
      end
    end)
  end

  defp upsert_relation(rel, org_id, client_id) do
    case Repo.get_by(ClientRelation, org_id: org_id, client_id: client_id, inn: rel["inn"]) do
      nil ->
        ClientRelation.changeset(%ClientRelation{}, %{
          client_id: client_id,
          org_id: org_id,
          full_name: rel["fullName"],
          inn: rel["inn"],
          position: rel["position"],
          role: rel["role"],
          date_begin: rel["dateBegin"],
          date_end: rel["dateEnd"]
        })
        |> Repo.insert()

      existing ->
        present_fields =
          for {camel_key, snake_key} <- @relation_camel_to_snake,
              not is_nil(rel[camel_key]),
              into: %{} do
            {snake_key, rel[camel_key]}
          end

        existing |> ClientRelation.actualize_changeset(present_fields) |> Repo.update()
    end
  end

  defp upsert_contacts(contacts, org_id, client_id) do
    Enum.reduce_while(contacts, :ok, fn contact, :ok ->
      case upsert_contact(contact, org_id, client_id) do
        {:ok, _} -> {:cont, :ok}
        {:error, _} = error -> {:halt, error}
      end
    end)
  end

  defp upsert_contact(contact, org_id, client_id) do
    case Repo.get_by(ClientContact, org_id: org_id, client_id: client_id, phone: contact["phone"]) do
      nil ->
        ClientContact.changeset(%ClientContact{}, %{
          client_id: client_id,
          org_id: org_id,
          phone: contact["phone"],
          email: contact["email"]
        })
        |> Repo.insert()

      existing ->
        present_fields =
          for {camel_key, snake_key} <- @contact_camel_to_snake,
              not is_nil(contact[camel_key]),
              into: %{} do
            {snake_key, contact[camel_key]}
          end

        existing |> ClientContact.actualize_changeset(present_fields) |> Repo.update()
    end
  end

  defp kafka_hosts do
    Application.get_env(:copm, :kafka_hosts, [{"localhost", 9092}])
  end
end
