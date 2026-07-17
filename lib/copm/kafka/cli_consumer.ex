defmodule Copm.Kafka.CliConsumer do
  use Broadway

  alias Broadway.Message
  alias Copm.Repo
  alias Copm.Schemas.{Client, ClientRelation, ClientContact}

  @topic "info.cli"

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
    Enum.each(messages, fn %{data: payload} ->
      upsert_client(payload)
    end)

    messages
  end

  defp upsert_client(payload) do
    client_attrs = %{
      client_id: payload["clientId"],
      client_status: payload["clientStatus"],
      registration_date: parse_datetime(payload["registrationDate"]),
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
      org_id: payload["orgId"]
    }

    Repo.insert!(
      Client.changeset(%Client{}, client_attrs),
      on_conflict: {:replace_all_except, [:inserted_at]},
      conflict_target: [:org_id, :client_id]
    )

    client_id = payload["clientId"]

    Enum.each(payload["relations"] || [], fn rel ->
      Repo.insert!(
        ClientRelation.changeset(%ClientRelation{}, %{
          client_id: client_id,
          org_id: payload["orgId"],
          full_name: rel["fullName"],
          inn: rel["inn"],
          position: rel["position"],
          role: rel["role"],
          date_begin: parse_date(rel["dateBegin"]),
          date_end: parse_date(rel["dateEnd"])
        }),
        on_conflict: :nothing
      )
    end)

    Enum.each(payload["contacts"] || [], fn contact ->
      Repo.insert!(
        ClientContact.changeset(%ClientContact{}, %{
          client_id: client_id,
          org_id: payload["orgId"],
          phone: contact["phone"],
          email: contact["email"]
        }),
        on_conflict: :nothing
      )
    end)
  end

  defp parse_datetime(nil), do: nil
  defp parse_datetime(dt), do: DateTime.from_iso8601(dt) |> elem(1)

  defp parse_date(nil), do: nil
  defp parse_date(d) when is_binary(d), do: Date.from_iso8601!(d)

  defp kafka_hosts do
    Application.get_env(:copm, :kafka_hosts, [{"localhost", 9092}])
  end
end
