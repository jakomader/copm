defmodule CopmWeb.SessionController do
  use CopmWeb, :controller


  def create(conn, %{"token" => token}) do
    case Phoenix.Token.verify(CopmWeb.Endpoint, "data_provider_session", token, max_age: 60) do
      {:ok, operator_id} -> conn |> put_session(:operator_id, operator_id) |> redirect(to: ~p"/upload")
      {:error, _} -> conn |> redirect(to: ~p"/login")
    end
  end
end
