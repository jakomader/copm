# Copm

Сервис на Elixir/Phoenix для приёма данных через Kafka, хранения в PostgreSQL со связями между сущностями и выдачи через GraphQL API.

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

Сущности связаны сквозными ключами: `clientId`, `userId`, `orderId`, `sessionId` — проходят через несколько блоков и реализованы как внешние ключи в БД, что позволяет делать вложенные GraphQL-запросы (например, клиент -> его заявки -> трекинг и платежи по каждой заявке).

## Стек

- **Backend:** Elixir 1.18 / Phoenix 1.8 (API-режим)
- **БД:** PostgreSQL 16 (Ecto)
- **Потоковая обработка:** Broadway + BroadwayKafka
- **API:** GraphQL (Absinthe + Dataloader)
- **Авторизация:** API-токены (SHA-256 хэш, `Authorization: Bearer`)
- **Инфраструктура:** Docker Compose (Kafka, Zookeeper, PostgreSQL, Kafdrop)

## Требования

- Elixir / Erlang OTP
- Docker + Docker Compose
- [mise](https://mise.jdx.dev/) (для сборки нативных Kafka-зависимостей нужен `cmake`)

## Запуск

```bash
docker-compose up -d

mise install

mix deps.get

mix ecto.setup

mix copm.gen_token "my-operator"
# Токен выводится один раз — сохрани его, восстановить нельзя

mix phx.server
```

## GraphQL API

Эндпоинт: `POST http://localhost:4000/api/graphql`

Требует заголовок:
```
Authorization: Bearer <токен из mix copm.gen_token>
```

Пример запроса:

```graphql
query {
  client(clientId: "ORG-001") {
    fullName
    inn
    orders {
      orderId
      orderStatus
      trackingEvents { statusCode eventTs }
      payments { amount paymentStatus }
    }
  }
}
```

## Мониторинг Kafka

Kafdrop (веб-дашборд для просмотра топиков, партиций, consumer-групп и сообщений):
```
http://localhost:9000
```

## Хранение данных

Kafka-топики: retention 30 дней
Записи в БД: срок хранения по каждому блоку данных зафиксирован в исходной таблице требований (3 года для большинства блоков, 1 год для IPDR)

```
