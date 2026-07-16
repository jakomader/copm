defmodule CopmWeb.Graphql.Middleware.RequireRole do
  @behaviour Absinthe.Middleware

  def call(resolution, required_roles) do
    case resolution.context[:cur_op] do
      nil -> Absinthe.Resolution.put_result(resolution, {:error, "unauthorized"})
      oper ->
        if oper.role in required_roles do
          resolution
        else
          Absinthe.Resolution.put_result(resolution, {:error, "You have no access to modify data"})
        end
    end
  end
end
