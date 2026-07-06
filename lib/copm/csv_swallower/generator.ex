defmodule Copm.CsvSwallower.Generator do
  alias Copm.CsvSwallower.Csv
  alias NimbleCSV.RFC4180, as: Parser

  @company_names ~w(Альфа Восток Сибирь Меридиан Балтика Гарант Прогресс Кама Волга Феникс)
  @company_suffixes ~w(Логистик Cargo Транс Групп Сервис)
  @cities ~w(Москва Санкт-Петербург Новосибирск Екатеринбург Казань Ростов-на-Дону Уфа Самара)
  @streets ~w(Ленина Мира Гагарина Советская Победы Центральная)
  @first_names_m ~w(Иван Пётр Сергей Александр Николай Дмитрий Владимир Алексей)
  @last_names_m ~w(Иванов Петров Сидоров Смирнов Кузнецов Попов Соколов Морозов)
  @patronymics_m ~w(Иванович Петрович Сергеевич Александрович Николаевич)
  @banks [
    {"Сбербанк", "044525225"},
    {"ВТБ", "044525187"},
    {"Альфа-Банк", "044525593"},
    {"Газпромбанк", "044525823"}
  ]

  @order_statuses ~w(CREATED CONFIRMED IN_TRANSIT DELIVERED CANCELLED)
  @order_types ~w(AIR AUTO MULTIMODAL INTERNATIONAL)
  @track_statuses ~w(PICKUP WAREHOUSE_IN DEPARTED ARRIVED DELIVERED)
  @payment_types ~w(INVOICE PREPAYMENT POSTPAYMENT REFUND)
  @payment_methods ~w(BANK_TRANSFER CARD ACCOUNT_DEBIT)
  @payment_statuses ~w(PENDING CONFIRMED FAILED REFUNDED)
  @channels ~w(CHAT_LK EMAIL PHONE MESSENGER)
  @event_types ~w(LOGIN LOGOUT PASSWORD_CHANGE)
  @protocols ~w(TCP UDP)
  @flags ~w(SYN FIN)

  def write(path, count, seed \\ 42) do
    :rand.seed(:exsss, {seed, seed * 7 + 1, seed * 13 + 3})

    fields = Csv.all_fields()
    header = [fields]

    data =
      1..count
      |> Enum.map(&build_row/1)
      |> Enum.map(fn row -> Enum.map(fields, &to_cell(Map.get(row, &1))) end)

    File.write!(path, Parser.dump_to_iodata(header ++ data))
    count
  end

  defp to_cell(nil), do: ""
  defp to_cell(value) when is_binary(value), do: value
  defp to_cell(value), do: Jason.encode!(value)

  defp build_row(i) do
    id = pad(i)
    client_id = "ORG-#{id}"
    order_id = "ORD-#{id}"

    {bank_name, bik} = pick(@banks)
    {to_bank_name, to_bik} = pick(@banks)
    inn = digits(10)
    full_name = "ООО \"#{pick(@company_names)} #{pick(@company_suffixes)}\""
    city = pick(@cities)

    %{
      # info.cli
      "clientId" => client_id,
      "clientStatus" => pick(~w(ACTIVE BLOCKED ARCHIVED)),
      "registrationDate" => iso_datetime(-800),
      "fullName" => full_name,
      "shortName" => maybe(pick(@company_names)),
      "inn" => inn,
      "kpp" => digits(9),
      "ogrn" => digits(13),
      "okpo" => maybe(digits(8)),
      "taxAgencyCode" => maybe(digits(4)),
      "legalAddress" => %{
        "city" => city,
        "street" => pick(@streets),
        "building" => "#{Enum.random(1..150)}"
      },
      "postalAddress" =>
        maybe(%{"city" => city, "street" => pick(@streets), "building" => "#{Enum.random(1..150)}"}),
      "regCountryCode" => "RU",
      "isForeign" => "false",
      "economicSector" => maybe("Логистика"),
      "bankInfo" => %{
        "bankName" => bank_name,
        "bik" => bik,
        "correspondentAccount" => "301018" <> digits(11),
        "settlementAccount" => "407028" <> digits(11)
      },
      "relations" => [
        %{
          "fullName" => person_name(),
          "inn" => digits(12),
          "position" => "Генеральный директор",
          "role" => pick(~w(SENDER RECEIVER PAYER)),
          "dateBegin" => iso_date(-400),
          "dateEnd" => nil
        }
      ],
      "contacts" => [%{"phone" => phone(), "email" => "info#{i}@example.ru"}],

      # info.user
      "userId" => "USR-#{id}",
      "login" => "u.#{i}@example.ru",
      "person.fullName" => person_name(),
      "person.phone" => phone(),
      "person.email" => "user#{i}@example.ru",
      "userStartsAt" => iso_datetime(-700),
      "userEndsAt" => nil,

      # info.aaa
      "sessionId" => "sess-#{hex(8)}",
      "sessionTs" => iso_datetime(-1),
      "eventType" => pick(@event_types),
      "ipAddress.ip" => ip(),
      "ipAddress.port" => "#{Enum.random(1024..65_535)}",
      "ipAddress.ipType" => "IPv4",
      "userAgent" => "Mozilla/5.0 (compatible; CopmFake/1.0)",
      "deviceId" => maybe("dev-#{hex(6)}"),
      "geolocation" => maybe("55.75,37.62"),

      # info.order
      "orderId" => order_id,
      "contractId" => "CNT-#{id}",
      "orderStatus" => pick(@order_statuses),
      "orderType" => pick(@order_types),
      "createdAt" => iso_datetime(-30),
      "confirmedAt" => iso_datetime(-29),
      "sender.clientId" => client_id,
      "sender.address" => "#{city}, #{pick(@streets)}",
      "sender.contactPerson" => "#{person_name()}, #{phone()}",
      "receiver.clientId" => "ORG-#{pad(i + 1000)}",
      "receiver.address" => "#{pick(@cities)}, #{pick(@streets)}",
      "receiver.contactPerson" => "#{person_name()}, #{phone()}",
      "routeFrom" => city,
      "routeTo" => pick(@cities),
      "transitPoints" => transit_points(),
      "carrier.name" => "#{pick(@company_names)} Карго",
      "carrier.inn" => digits(10),
      "flightNumber" => maybe("SU-#{Enum.random(100..999)}"),
      "vehicleNumber" => maybe("А#{Enum.random(100..999)}ВС77"),
      "awbNumber" => maybe(digits(11)),
      "cmrNumber" => maybe(digits(8)),
      "cargoDescription" => "Промышленное оборудование",
      "cargoWeight" => "#{Enum.random(10..20_000)}.#{Enum.random(0..9)}",
      "cargoVolume" => maybe("#{Enum.random(1..100)}.#{Enum.random(0..9)}"),
      "cargoDangerClass" => maybe("ADR #{Enum.random(1..9)}"),
      "cargoSpecialConditions" => maybe("Температурный режим +2..+8"),
      "insuranceInfo.policyNumber" => maybe("INS-#{id}"),
      "insuranceInfo.amount" => maybe("#{Enum.random(10_000..500_000)}"),
      "customsInfo.declarationNumber" => maybe(digits(10)),
      "customsInfo.brokerInn" => maybe(digits(10)),
      "estimatedDeliveryDate" => iso_date(2),
      "actualDeliveryDate" => iso_date(3),

      # info.track
      "trackingId" => "TRK-#{id}",
      "eventTs" => iso_datetime(-1),
      "statusCode" => pick(@track_statuses),
      "statusDescription" => maybe("Груз прошёл таможенное оформление"),
      "location.address" => "#{city}, #{pick(@streets)}",
      "location.city" => city,
      "location.coordinates" => maybe("55.75,37.62"),
      "operatorId" => maybe("OP-#{Enum.random(1..50)}"),
      "scannedDeviceId" => maybe("scn-#{hex(6)}"),

      # info.payment
      "paymentId" => "PAY-#{id}",
      "paymentTs" => iso_datetime(-2),
      "paymentType" => pick(@payment_types),
      "paymentMethod" => pick(@payment_methods),
      "amount" => "#{Enum.random(1000..500_000)}.00",
      "currency" => "RUB",
      "invoiceNumber" => "INV-#{id}",
      "from.bankInfo" => %{
        "bankName" => bank_name,
        "bik" => bik,
        "account" => "408028" <> digits(11),
        "inn" => inn
      },
      "to.bankInfo" => %{
        "bankName" => to_bank_name,
        "bik" => to_bik,
        "account" => "407028" <> digits(11)
      },
      "paymentStatus" => pick(@payment_statuses),
      "externalPaymentId" => maybe("EXT-#{hex(8)}"),
      "ipAddress" => ip(),

      # info.msg
      "conversationId" => "CONV-#{id}",
      "startsAt" => iso_datetime(-5),
      "endsAt" => maybe(iso_datetime(-4)),
      "channel" => pick(@channels),
      "messageId" => "MSG-#{id}",
      "messageTs" => iso_datetime(-4),
      "messageText" => "Добрый день! Уточните, пожалуйста, статус заявки.",
      "attachments" => maybe_list(["https://files.example.ru/doc-#{hex(6)}.pdf"]),
      "operatorLogin" => maybe("operator.#{Enum.random(1..20)}"),
      "relatedOrderId" => maybe(order_id),

      # info.ipdr
      "ts" => iso_datetime(0),
      "sourceIp" => ip(),
      "sourcePort" => "#{Enum.random(1024..65_535)}",
      "destinationIp" => "10.0.#{Enum.random(0..255)}.#{Enum.random(1..254)}",
      "destinationPort" => "443",
      "protocol" => pick(@protocols),
      "flag" => maybe(pick(@flags)),
      "bytesTransferred" => "#{Enum.random(200..500_000)}"
    }
  end

  defp pick(list), do: Enum.random(list)

  defp maybe(value, probability \\ 0.8) do
    if :rand.uniform() < probability, do: value, else: nil
  end

  defp maybe_list(list, probability \\ 0.6) do
    if :rand.uniform() < probability, do: list, else: []
  end

  defp digits(n), do: 1..n |> Enum.map(fn _ -> Enum.random(0..9) end) |> Enum.join()

  defp hex(n) do
    1..n
    |> Enum.map(fn _ -> Enum.random(~c"0123456789abcdef") end)
    |> List.to_string()
  end

  defp pad(i), do: i |> Integer.to_string() |> String.pad_leading(3, "0")

  defp person_name, do: "#{pick(@last_names_m)} #{pick(@first_names_m)} #{pick(@patronymics_m)}"

  defp phone do
    "+7 9#{Enum.random(10..99)} #{Enum.random(100..999)}-#{Enum.random(10..99)}-#{Enum.random(10..99)}"
  end

  defp ip do
    "#{Enum.random(1..223)}.#{Enum.random(0..255)}.#{Enum.random(0..255)}.#{Enum.random(1..254)}"
  end

  defp transit_points do
    if :rand.uniform() < 0.5 do
      Enum.take_random(@cities, Enum.random(1..2))
    else
      []
    end
  end

  defp iso_datetime(day_offset) do
    DateTime.utc_now()
    |> DateTime.add(day_offset * 86_400, :second)
    |> DateTime.truncate(:second)
    |> DateTime.to_iso8601()
  end

  defp iso_date(day_offset) do
    Date.utc_today() |> Date.add(day_offset) |> Date.to_iso8601()
  end
end
