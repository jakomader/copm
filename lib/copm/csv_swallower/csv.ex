defmodule Copm.CsvSwallower.Csv do


  alias NimbleCSV.RFC4180, as: Parser

  @topic_order ~w(
    info.cli info.user info.aaa info.order info.track info.payment info.msg info.ipdr
  )

  @topics %{
    "info.cli" => %{
      fields: ~w(
        clientId clientStatus registrationDate fullName shortName inn kpp ogrn
        okpo taxAgencyCode legalAddress postalAddress regCountryCode isForeign
        economicSector bankInfo relations contacts
      ),
      structured: MapSet.new(~w(legalAddress postalAddress bankInfo relations contacts))
    },
    "info.user" => %{
      fields: ~w(userId clientId login person.fullName person.phone person.email userStartsAt userEndsAt),
      structured: MapSet.new([])
    },
    "info.aaa" => %{
      fields: ~w(
        userId sessionId sessionTs eventType ipAddress.ip ipAddress.port
        ipAddress.ipType userAgent deviceId geolocation
      ),
      structured: MapSet.new([])
    },
    "info.order" => %{
      fields: ~w(
        orderId contractId clientId userId orderStatus orderType createdAt
        confirmedAt sender.clientId sender.address sender.contactPerson
        receiver.clientId receiver.address receiver.contactPerson routeFrom
        routeTo transitPoints carrier.name carrier.inn flightNumber
        vehicleNumber awbNumber cmrNumber cargoDescription cargoWeight
        cargoVolume cargoDangerClass cargoSpecialConditions
        insuranceInfo.policyNumber insuranceInfo.amount
        customsInfo.declarationNumber customsInfo.brokerInn
        estimatedDeliveryDate actualDeliveryDate
      ),
      structured: MapSet.new(~w(transitPoints))
    },
    "info.track" => %{
      fields: ~w(
        trackingId orderId eventTs statusCode statusDescription
        location.address location.city location.coordinates operatorId
        scannedDeviceId
      ),
      structured: MapSet.new([])
    },
    "info.payment" => %{
      fields: ~w(
        paymentId orderId clientId userId paymentTs paymentType paymentMethod
        amount currency invoiceNumber from.bankInfo to.bankInfo paymentStatus
        externalPaymentId sessionId ipAddress
      ),
      structured: MapSet.new(~w(from.bankInfo to.bankInfo))
    },
    "info.msg" => %{
      fields: ~w(
        conversationId clientId userId sessionId startsAt endsAt channel
        messageId messageTs messageText attachments operatorLogin ipAddress
        relatedOrderId
      ),
      structured: MapSet.new(~w(attachments))
    },
    "info.ipdr" => %{
      fields: ~w(ts sourceIp sourcePort destinationIp destinationPort protocol flag bytesTransferred),
      structured: MapSet.new([])
    }
  }

  @all_fields @topic_order |> Enum.flat_map(fn x -> @topics[x].fields end) |> Enum.uniq()

  def all_fields, do: @all_fields
  def topics, do: @topic_order
  def fields(topic), do: @topics[topic][:fields]
  def structured(topic), do: @topics[topic][:structured]

  def decode(file) do
    fields = @all_fields
    structured = all_structured()

    file
    |> File.stream!()
    |> Parser.parse_stream()
    |> Enum.map(fn x -> build_row(x, fields, structured) end)
  end

  def split_by_topic({:error, _} = error), do: error

  def split_by_topic({:ok, row}) do
    payloads =
      @topic_order
      |> Enum.map(fn topic -> {topic, build_payload(row, fields(topic))} end)
      |> Map.new()

    {:ok, payloads}
  end

  defp all_structured do
    @topic_order
    |> Enum.flat_map(fn x -> MapSet.to_list(structured(x)) end)
    |> MapSet.new()
  end

  defp build_row(values, fields, structured) do
    if length(values) == length(fields) do
      fields
      |> Enum.zip(values)
      |> Enum.reduce_while({:ok, %{}}, fn {field, value}, {:ok, acc} ->
        case cast_field(field, value, structured) do
          {:ok, casted} -> {:cont, {:ok, Map.put(acc, field, casted)}}
          {:error, reason} -> {:halt, {:error, {field, reason}}}
        end
      end)
    else
      {:column_count_mismatch}
    end
  end

  defp cast_field(_field, "", _structured), do: {:ok, nil}

  defp cast_field(field, value, structured) do
    if MapSet.member?(structured, field) do
      Jason.decode(value)
    else
      {:ok, value}
    end
  end

  defp build_payload(row, topic_fields) do
    Enum.reduce(topic_fields, %{}, fn field, acc ->
      put_nested(acc, String.split(field, "."), Map.get(row, field))
    end)
  end

  defp put_nested(acc, [key], value), do: Map.put(acc, key, value)

  defp put_nested(acc, [key | rest], value) do
    nested = Map.get(acc, key) || %{}
    Map.put(acc, key, put_nested(nested, rest, value))
  end
end
