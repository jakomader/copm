defmodule CopmWeb.Graphql.Middleware.RequireAuth do
  @behaviour Absinthe.Middleware

  def call(resolution, _config) do
    case resolution.context[:cur_op] do
      nil -> Absinthe.Resolution.put_result(resolution, {:error, "unauthorized"})
      _ -> resolution
    end
  end
end
