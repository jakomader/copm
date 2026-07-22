defmodule CopmWeb.SessionController do
  use CopmWeb, :controller


  def create(conn, %{"t" => token}) do
      case Phoenix.Token.verify(CopmWeb.Endpoint, "admin_session", token, max_age: 60) do
        {:ok, operator_id} -> conn |> put_session(:operator_id, operator_id) |> redirect(to: ~p"/admin/users/admins")
        {:error, _} -> conn |> redirect(to: ~p"/login")
      end
  end
end
