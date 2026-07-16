defmodule CopmWeb.RedirectToLogin do
  use CopmWeb, :controller
  def redirect_to_login(conn, _params) do
    redirect(conn, to: ~p"/login")
  end
end
