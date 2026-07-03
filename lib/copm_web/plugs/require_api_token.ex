defmodule CopmWeb.Plugs.RequireApiToken do
  @moduledoc """
  This module has only one purpose - to require a vaild `Authorization: Bearer <token> header. It halts with 401 error(invalid auth).
  when the header is missing or token is incorrect.
  """

  import Plug.Conn

  alias Copm.Auth

  def init(opts), do: opts

  def call(conn, _opts) do
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         {:ok, _api_token} <- Auth.verify_token(token) do
         conn
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
