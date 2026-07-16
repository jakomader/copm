defmodule CopmWeb.RequireAdminHook do
  import Phoenix.LiveView

  alias Copm.Repo
  alias Copm.Schemas.Operators

  def on_mount(:default, _params, session, socket) do
    with operator_id when not is_nil(operator_id) <- session["operator_id"],
         %Operators{role: "admin"} = operator <- Repo.get(Operators, operator_id) do
      {:cont, Phoenix.Component.assign(socket, :current_operator, operator)}
    else
      _ -> {:halt, redirect(socket, to: "/login")}
    end
  end
end
