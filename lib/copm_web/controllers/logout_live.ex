defmodule CopmWeb.LogoutController do
  use CopmWeb, :controller
  def delete(conn, _params) do
  conn
  |> configure_session(drop: true)
  |> redirect(to: ~p"/login")
  end

end
