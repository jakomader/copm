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
        description: "Адаптер приёма данных от поставщиков: JSON по одному объекту за раз, загрузка CSV-файлом целиком, проверка статуса обработки."
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
