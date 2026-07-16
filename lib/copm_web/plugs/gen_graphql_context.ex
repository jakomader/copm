defmodule CopmWeb.Plugs.GenGraphQlContext do


  import Plug.Conn

  alias Copm.Auth

  def init(opts), do: opts

  def call(conn, _opts) do
    operator =
      case get_req_header(conn, "authorization") do
        ["Bearer " <> token] ->
          case Auth.verify_token(token) do
            {:ok, oper} -> oper
            _ -> nil
          end
        _ -> nil

      end
    Absinthe.Plug.put_options(conn, context: %{cur_op: operator})

  end

end
