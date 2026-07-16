defmodule CopmWeb.DataProviderCheck do
  import Plug.Conn
  alias Copm.Auth
  def init(opts), do: opts
  def call(conn, _opts) do
  with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
       {:ok, %{role: "data_provider"} = operator} <- Auth.verify_token(token) do
    assign(conn, :current_operator, operator)
  else
    _ -> unauthorized(conn)
  end
end
  defp unauthorized(conn) do
    conn
    |> put_status(:unauthorized)
    |> Phoenix.Controller.json(%{error: "unauthorized"})
    |> halt()
  end
end
