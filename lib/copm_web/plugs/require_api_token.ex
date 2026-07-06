defmodule CopmWeb.Plugs.RequireApiToken do
  @moduledoc """
  Требует валидный `Authorization: Bearer <token>` от оператора с ролью
  `queries_only`. Останавливает запрос с 401, если токена нет, он неверен,
  либо принадлежит оператору с другой ролью (например, data_provider).
  """

  import Plug.Conn

  alias Copm.Auth

  def init(opts), do: opts

  def call(conn, _opts) do
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         {:ok, %{role: "queries_only"} = operator} <- Auth.verify_token(token) do
      assign(conn, :current_operator, operator)
    else
      _ -> unauthorized(conn)
    end
  end

  defp unauthorized(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(401, Jason.encode!(%{errors: [%{message: "Unauthorized user"}]}))
    |> halt()
  end
end
