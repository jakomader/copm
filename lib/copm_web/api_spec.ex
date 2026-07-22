defmodule CopmWeb.ApiSpec do
  alias OpenApiSpex.{Components, Info, MediaType, OpenApi, Operation, PathItem, RequestBody, Response, Schema, Server}

  @behaviour OpenApi

  @impl OpenApi
  def spec do
    %OpenApi{
      servers: [Server.from_endpoint(CopmWeb.Endpoint)],
      info: %Info{
        title: "Микросервис Шина данных REST ingest API",
        version: "1.0.0",
        description: """
        Адаптер приёма данных от поставщиков: JSON по одному объекту за раз, загрузка CSV-файлом целиком, проверка статуса обработки.

        ## Актуализация данных

        Отдельного эндпоинта для актуализации нет - она происходит через те же `POST /api/ingest/:topic` и `POST /api/ingest/csv`, что и создание. Система сама определяет, что делать, по составному ключу `(orgId, <бизнес-идентификатор>)`:

        - **Ключа ещё нет** - запись создаётся, все обязательные поля должны быть заполнены (как обычно).
        - **Ключ уже есть** - это актуализация, здесь действуют другие правила:
          1. Разрешено присылать **только обязательные поля** сущности (по списку обязательных полей на топик) - сам бизнес-ключ (например, `clientId`) в их число не входит, это не обновляемое поле, а идентификатор записи.
          2. Если в payload встретилось **необязательное или неизвестное поле** - вся актуализация целиком отклоняется с ошибкой, ничего не применяется.
          3. Обязательно нужно прислать **хотя бы одно** поле, отличающееся от текущего значения - пустая или "ничего не меняющая" актуализация тоже отклоняется с ошибкой.
          4. Поля, которые **не прислали**, не трогаются - сохраняют то значение, что было. Занулить (`null`) поле, отправив его явно, тоже нельзя - обязательное поле не может стать пустым.

        Бизнес-ключи по сущностям:

        | Сущность | Ключ актуализации |
        |---|---|
        | Клиент (`cli`) | `orgId` + `clientId` |
        | Пользователь ЛК (`user`) | `orgId` + `userId` |
        | Заявка (`order`) | `orgId` + `orderId` |
        | Трекинг (`track`) | `orgId` + `trackingId` |
        | Платёж (`payment`) | `orgId` + `paymentId` |
        | Переписка (`msg`, conversation) | `orgId` + `conversationId` |
        | Сообщение (`msg`, message) | `orgId` + `messageId` |
        | Уполномоченное лицо (`relations[]` внутри `cli`) | `orgId` + `clientId` + `inn` |
        | Контакт (`contacts[]` внутри `cli`) | `orgId` + `clientId` + `phone` |

        Для `aaa` (события авторизации) и `ipdr` (сетевые соединения) актуализация не предусмотрена - это записи лога однократных событий, а не сущности с изменяемым состоянием; каждая публикация создаёт новую запись.

        Ответ REST-эндпоинта (`{"ok": N, "errors": 0}`) отражает только успешную публикацию в Kafka, а не результат самой актуализации - она происходит асинхронно на стороне consumer'а. Ошибки актуализации в текущей версии не возвращаются вызывающей стороне.

        ## Проверка статуса пакетной загрузки (транзакции)

        Ответ `{"ok": N, "errors": 0}` от `POST /api/ingest/:topic` или `/api/ingest/csv` отражает только факт публикации в Kafka, а не то, дошли ли данные до итогового хранилища на самом деле - актуализация и вставка происходят асинхронно, уже после ответа на HTTP-запрос.

        Чтобы проверить реальный результат, каждый такой ответ дополнительно содержит `batchId` - идентификатор именно этой отправки (один HTTP-вызов = один батч, даже если в нём одна запись). Статус по нему доступен через `GET /api/ingest/batches/{id}` и проходит через три состояния:

        1. **`processing`** - консьюмер ещё не обработал все записи батча (`processed < total`).
        2. **`Доставлено`** - все записи батча дошли до итогового хранилища без единой ошибки.
        3. **Ошибки присутствуют** - хотя бы одна запись не прошла (неизвестное поле при актуализации, невалидное значение, отсутствующий бизнес-ключ и т.д.) - возвращается список конкретных ошибок с указанием, какая именно запись (по бизнес-ключу или порядковому номеру в пакете) и почему не прошла.

        Ошибки, которые видны сразу в ответе на `POST` (например, отсутствие ключевого поля до публикации в Kafka), уже учтены в счётчике `processed` и в списке ошибок батча - повторно они не появятся после обработки консьюмером.
        """
      },
      components: %Components{
        securitySchemes: %{
          "bearerAuth" => %OpenApiSpex.SecurityScheme{
            type: "http",
            scheme: "bearer",
            description: "Access-токен оператора, полученный через GraphQL-мутацию sessionCreate."
          }
        }
      },
      paths:
        CopmWeb.Router
        |> OpenApiSpex.Paths.from_router()
        |> Map.put("/api/graphql", graphql_path_item())
    }
    |> OpenApiSpex.resolve_schema_modules()
  end

  defp graphql_path_item do
    %PathItem{
      post: %Operation{
        tags: ["auth"],
        summary: "Получение и обновление access-токена (GraphQL)",
        description: """
        Авторизация во всей системе устроена единообразно для всех ролей через GraphQL-мутации:

        * `sessionCreate(login, password)` - вход по логину/паролю, возвращает access-токен (живёт 15 минут), refresh-токен (живёт 30 дней) и модель оператора.
        * `sessionRefresh(refreshToken)` - обновление access-токена по refresh-токену, без повторного ввода пароля. Возвращает новую пару токенов.

        Полученный `token` используйте в заголовке `Authorization: Bearer <token>` для остальных REST-эндпоинтов этой документации.
        """,
        operationId: "graphqlSession",
        requestBody: %RequestBody{
          required: true,
          content: %{
            "application/json" => %MediaType{
              schema: %Schema{
                type: :object,
                properties: %{query: %Schema{type: :string}},
                required: [:query]
              },
              examples: %{
                "sessionCreate" => %OpenApiSpex.Example{
                  summary: "Получить токен по логину и паролю",
                  value: %{
                    "query" =>
                      "mutation { sessionCreate(login: \"my_login\", password: \"my_password\") { token expiresIn refreshToken operator { login role } } }"
                  }
                },
                "sessionRefresh" => %OpenApiSpex.Example{
                  summary: "Обновить токен по refresh-токену",
                  value: %{
                    "query" =>
                      "mutation { sessionRefresh(refreshToken: \"YOUR_REFRESH_TOKEN\") { token expiresIn refreshToken } }"
                  }
                }
              }
            }
          }
        },
        responses: %{
          200 => %Response{
            description: "Результат GraphQL-запроса (структура data.sessionCreate / data.sessionRefresh)",
            content: %{
              "application/json" => %MediaType{schema: %Schema{type: :object}}
            }
          }
        }
      }
    }
  end
end
