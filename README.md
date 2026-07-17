# Copm

Сервис на Elixir/Phoenix для приёма данных через Kafka, хранения в PostgreSQL со связями между сущностями и выдачи через GraphQL API.

**[Сслыка на docs с приложениями к проекту.](https://docs.google.com/document/d/1tdfFQEyxC0QncNc7EgVl71uE_sVMQs7pyo7nxp_O6aQ/edit?usp=sharing)**



## Общая идея проекта


Данные в БД передаются неким лицом - заполнение будет осуществляться на фронтенде или в JSON-формате. Это лицо (оператор, интегрированная система поставщика или иной источник) вносит информацию о клиентах, заявках, платежах и прочих сущностях. Введённые данные упаковываются в событие и отправляются в Kafka - промежуточный буфер, который принимает поток входящих сообщений независимо от нагрузки и скорости их обработки на стороне сервиса.

Далее эти данные подхватываются consumer-частью сервиса, разбираются согласно структуре события и сохраняются в PostgreSQL с установлением всех необходимых связей между сущностями - клиентом, его заявками, платежами, трекингом груза и так далее.

С другой стороны системы находится лицо, которому эти данные необходимы для работы - оператор, аналитик или иной потребитель информации. Он не обращается к базе данных напрямую, а делает запрос через GraphQL API, указывая какие именно данные и в каком объёме ему нужны - будь то карточка одного клиента со всей историей его взаимодействий, либо список всех заявок за период, либо детализация конкретного платежа. Сервис собирает ответ, подгружая только запрошенные связи, и возвращает результат в удобном для отображения виде.
Весь продукт представляет собой связующее звено между стороной, которая данные поставляет, и стороной, которая эти данные впоследствии потребляет - с гарантией того, что информация между этими сторонами не теряется(kafka обеспечивает эту бесперебойность, т.к там есть система репликаций и в случае выхода брокера из строя, гарантированно найдётся брокер с теми же сущностями), сохраняет целостность связей и доступна к выборке в любой момент в пределах установленного срока хранения.

### Блок 0 -получение списка всех организаций
query ListOrganizations {
  organizations {
    id
    orgName
  }
}

### Блок 1 - Клиент

`client` (точечный поиск) требует `orgId` — `clientId` сам по себе больше не уникален, его может использовать несколько разных логистических компаний одновременно.

```graphql
query GetClient {
  client(orgId: 1, clientId: "ORG-001") {
    clientId
    orgId
    fullName
    inn
    clientStatus
    legalAddress
    bankInfo
    relations { fullName role position }
    contacts { phone email }
  }
}
```

`clients` (список) — `orgId` необязателен: не указан — поиск идёт по всем компаниям сразу, указан — только внутри одной.

```graphql
query ListClients {
  clients(orgId: 1, inn: "7707083893", status: "ACTIVE", limit: 20, offset: 0) {
    clientId
    orgId
    fullName
    clientStatus
    registrationDate
  }
}
```

Межкомпанийный поиск по ФИО/названию или телефону клиента (без `orgId` — по всем компаниям сразу):

```graphql
query SearchClientsAcrossCompanies {
  clients(fullName: "Иванов", limit: 20, offset: 0) {
    clientId
    orgId
    fullName
  }
}

query SearchClientsByPhone {
  clients(phone: "+79990000000") {
    clientId
    orgId
    fullName
    contacts { phone }
  }
}
```

### Блок 2 - Пользователи ЛК + AAA

`user` требует `orgId` (аналогично `client`).

```graphql
query GetUser {
  user(orgId: 1, userId: "USR-001") {
    userId
    orgId
    login
    person
    client { fullName }
  }
}
```

```graphql
query UsersByClient {
  usersByClient(orgId: 1, clientId: "ORG-001") {
    userId
    login
    userStartsAt
  }
}
```

```graphql
query AuthEvents {
  authEvents(orgId: 1, userId: "USR-001", sessionId: "sess-abc", eventType: "LOGIN", limit: 50, offset: 0) {
    id
    sessionId
    eventType
    sessionTs
    ipAddress
    userAgent
  }
}
```

### Блок 3 - Заявки

`order` требует `orgId`.

```graphql
query GetOrder {
  order(orgId: 1, orderId: "ORD-001") {
    orderId
    orgId
    orderStatus
    orderType
    cargoDescription
    cargoWeight
    sender
    receiver
    client { fullName }
    user { login }
  }
}
```

```graphql
query ListOrders {
  orders(orgId: 1, clientId: "ORG-001", userId: "USR-001", status: "CONFIRMED", orderType: "AIR", limit: 20, offset: 0) {
    orderId
    orderStatus
    routeFrom
    routeTo
  }
}
```

### Блок 4 - Трекинг

`trackingEvents` — `orgId` необязателен (фильтр). `trackingEvent` (точечный) — `orgId` обязателен.

```graphql
query TrackingByOrder {
  trackingEvents(orgId: 1, orderId: "ORD-001") {
    trackingId
    statusCode
    eventTs
    location
  }
}
```

```graphql
query GetTrackingEvent {
  trackingEvent(orgId: 1, trackingId: "TRK-001") {
    trackingId
    statusCode
    statusDescription
    order { orderId }
  }
}
```

### Блок 5 - Платежи

`payment` требует `orgId`.

```graphql
query GetPayment {
  payment(orgId: 1, paymentId: "PAY-001") {
    paymentId
    amount
    currency
    paymentStatus
    fromBankInfo
    toBankInfo
  }
}
```

```graphql
query ListPayments {
  payments(orgId: 1, orderId: "ORD-001", clientId: "ORG-001", status: "CONFIRMED", limit: 20, offset: 0) {
    paymentId
    amount
    paymentStatus
    paymentTs
  }
}
```

### Блок 6 - Коммуникации

`conversation` требует `orgId`.

```graphql
query GetConversation {
  conversation(orgId: 1, conversationId: "CONV-001") {
    conversationId
    channel
    startsAt
    endsAt
    messages {
      messageId
      messageText
      messageTs
    }
  }
}
```

```graphql
query ListConversations {
  conversations(orgId: 1, clientId: "ORG-001", userId: "USR-001", channel: "CHAT_LK", limit: 20, offset: 0) {
    conversationId
    channel
    startsAt
  }
}
```

### Блок 7 - IPDR

```graphql
query IpdrRecords {
  ipdrRecords(orgId: 1, sourceIp: "192.168.1.1", fromTs: "2026-07-01T00:00:00Z", toTs: "2026-07-03T00:00:00Z", limit: 100, offset: 0) {
    id
    ts
    sourceIp
    destinationIp
    protocol
    bytesTransferred
  }
}
```

### Сквозной запрос - демонстрация связей между блоками

```graphql
query FullClientTree {
  client(orgId: 1, clientId: "ORG-001") {
    fullName
    inn
    users {
      login
      authEvents { eventType sessionTs }
    }
    orders {
      orderId
      orderStatus
      trackingEvents { statusCode eventTs }
      payments { amount paymentStatus }
    }
  }
}
```

### Про `orgId`

- На точечных запросах (`client`, `user`, `order`, `trackingEvent`, `conversation`, `payment`) `orgId` **обязателен** — бизнес-ключ (`clientId`, `orderId` и т.д.) сам по себе не уникален, его может использовать несколько разных логистических компаний одновременно, поэтому без `orgId` невозможно однозначно определить нужную запись.
- На списочных запросах (`clients`, `usersByClient`, `authEvents`, `orders`, `trackingEvents`, `conversations`, `payments`, `ipdrRecords`) `orgId` **необязателен** — не указан, значит поиск по всем компаниям сразу; указан — только внутри одной.
- Каждый объект в ответе содержит собственное поле `orgId`, чтобы при межкомпанийном поиске было видно, какой компании принадлежит конкретная запись.
