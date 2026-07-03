defmodule CopmWeb.Router do
  use CopmWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :graphql do
    plug :accepts, ["json"]
  end

  scope "/api" do
    pipe_through :graphql

    forward "/graphql", Absinthe.Plug,
      schema: CopmWeb.GraphQL.Schema

  end
  scope "/api", CopmWeb do
    pipe_through :api
  end
end
