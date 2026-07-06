# Copm

Сервис на Elixir/Phoenix для приёма данных через Kafka, хранения в PostgreSQL со связями между сущностями и выдачи через GraphQL API.

**[Сслыка на docs с приложениями к проекту.](https://docs.google.com/document/d/1tdfFQEyxC0QncNc7EgVl71uE_sVMQs7pyo7nxp_O6aQ/edit?usp=sharing)**



## Общая идея проекта


Данные в БД передаются неким лицом - заполнение будет осуществляться на фронтенде или в JSON-формате. Это лицо (оператор, интегрированная система поставщика или иной источник) вносит информацию о клиентах, заявках, платежах и прочих сущностях. Введённые данные упаковываются в событие и отправляются в Kafka - промежуточный буфер, который принимает поток входящих сообщений независимо от нагрузки и скорости их обработки на стороне сервиса.

Далее эти данные подхватываются consumer-частью сервиса, разбираются согласно структуре события и сохраняются в PostgreSQL с установлением всех необходимых связей между сущностями - клиентом, его заявками, платежами, трекингом груза и так далее.

С другой стороны системы находится лицо, которому эти данные необходимы для работы - оператор, аналитик или иной потребитель информации. Он не обращается к базе данных напрямую, а делает запрос через GraphQL API, указывая какие именно данные и в каком объёме ему нужны - будь то карточка одного клиента со всей историей его взаимодействий, либо список всех заявок за период, либо детализация конкретного платежа. Сервис собирает ответ, подгружая только запрошенные связи, и возвращает результат в удобном для отображения виде.
Весь продукт представляет собой связующее звено между стороной, которая данные поставляет, и стороной, которая эти данные впоследствии потребляет - с гарантией того, что информация между этими сторонами не теряется(kafka обеспечивает эту бесперебойность, т.к там есть система репликаций и в случае выхода брокера из строя, гарантированно найдётся брокер с теми же сущностями), сохраняет целостность связей и доступна к выборке в любой момент в пределах установленного срока хранения.

## Архитектура

```
Поставщик -> Kafka (8 топиков) -> Broadway consumers -> PostgreSQL -> GraphQL -> клиент
```

Данные я разбил на 8 блоков, каждый со своим Kafka-топиком и таблицей (или несколькими) в БД:

| Блок | Топик | Таблицы |
|---|---|---|
| Клиент (ЮЛ/ИП) | `info.cli` | `clients`, `client_relations`, `client_contacts` |
| Пользователи ЛК | `info.user` | `users` |
| AAA (сессии/входы) | `info.aaa` | `auth_events` |
| Заявки и договоры | `info.order` | `orders` |
| Трекинг груза | `info.track` | `tracking_events` |
| Платёжные операции | `info.payment` | `payments` |
| Коммуникации | `info.msg` | `conversations`, `messages` |
| IPDR (сетевые соединения) | `info.ipdr` | `ipdr_records` |

Сущности связаны сквозными ключами: `clientId`, `userId`, `orderId`, `sessionId` - проходят через несколько блоков и реализованы как внешние ключи в БД, что позволяет делать вложенные GraphQL-запросы (например, клиент -> его заявки -> трекинг и платежи по каждой заявке).

## Стек

- **Backend:** Elixir / Phoenix
- **БД:** PostgreSQL (Ecto)
- **Потоковая обработка:** Broadway + BroadwayKafka
- **API:** GraphQL (Absinthe + Dataloader)
- **Авторизация:** API-токены (SHA-256 хэш, `Authorization: Bearer`)
- **Инфраструктура:** Docker Compose (Kafka, Zookeeper, PostgreSQL, Kafdrop)

## Запуск

```bash
docker-compose up -d

mise install

mix deps.get

mix ecto.setup

mix copm.gen_token "my-operator"


mix phx.server
```

## GraphQL API

Эндпоинт: `POST http://localhost:4000/api/graphql`

Требует заголовок:
```
Authorization: Bearer <токен из mix copm.gen_token>
```


## Мониторинг Kafka

Было принято решение вынести логику получения данных из описания типов в отдельные модули-резолверы. Типы остаются декларативным описанием схемы (какие поля существуют, какие у них связи), а резолверы содержат императивную логику выборки (фильтрация, работа с БД, обработка ошибок). Цель - разделить контракт данных и его реализацию, чтобы менять один без затрагивания другого.
Kafdrop (веб-дашборд для просмотра топиков, партиций, consumer-групп и сообщений):
```
http://localhost:9000
```

## Хранение данных

Kafka-топики: retention 30 дней
Записи в БД: срок хранения по каждому блоку данных зафиксирован в исходной таблице требований (3 года для большинства блоков, 1 год для IPDR)

## Доступные запросы

Все запросы - `POST /api/graphql`, с заголовком `Authorization: Bearer <токен>`.

Я не добавлял pipeline для graphiql, так что запросы можно инициировать через curl либо через postman(или любой другой аггрегатор) 

### Блок 1 - Клиент

```graphql
query GetClient {
  client(clientId: "ORG-001") {
    clientId
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

```graphql
query ListClients {
  clients(inn: "7707083893", status: "ACTIVE", limit: 20, offset: 0) {
    clientId
    fullName
    clientStatus
    registrationDate
  }
}
```

### Блок 2 - Пользователи ЛК + AAA

```graphql
query GetUser {
  user(userId: "USR-001") {
    userId
    login
    person
    client { fullName }
  }
}
```

```graphql
query UsersByClient {
  usersByClient(clientId: "ORG-001") {
    userId
    login
    userStartsAt
  }
}
```

```graphql
query AuthEvents {
  authEvents(userId: "USR-001", sessionId: "sess-abc", eventType: "LOGIN", limit: 50, offset: 0) {
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

```graphql
query GetOrder {
  order(orderId: "ORD-001") {
    orderId
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
  orders(clientId: "ORG-001", userId: "USR-001", status: "CONFIRMED", orderType: "AIR", limit: 20, offset: 0) {
    orderId
    orderStatus
    routeFrom
    routeTo
  }
}
```

### Блок 4 - Трекинг

```graphql
query TrackingByOrder {
  trackingEvents(orderId: "ORD-001") {
    trackingId
    statusCode
    eventTs
    location
  }
}
```

```graphql
query GetTrackingEvent {
  trackingEvent(trackingId: "TRK-001") {
    trackingId
    statusCode
    statusDescription
    order { orderId }
  }
}
```

### Блок 5 - Платежи

```graphql
query GetPayment {
  payment(paymentId: "PAY-001") {
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
  payments(orderId: "ORD-001", clientId: "ORG-001", status: "CONFIRMED", limit: 20, offset: 0) {
    paymentId
    amount
    paymentStatus
    paymentTs
  }
}
```

### Блок 6 - Коммуникации

```graphql
query GetConversation {
  conversation(conversationId: "CONV-001") {
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
  conversations(clientId: "ORG-001", userId: "USR-001", channel: "CHAT_LK", limit: 20, offset: 0) {
    conversationId
    channel
    startsAt
  }
}
```

### Блок 7 - IPDR

```graphql
query IpdrRecords {
  ipdrRecords(sourceIp: "192.168.1.1", fromTs: "2026-07-01T00:00:00Z", toTs: "2026-07-03T00:00:00Z", limit: 100, offset: 0) {
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
  client(clientId: "ORG-001") {
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
