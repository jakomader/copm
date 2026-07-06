defmodule CopmWeb.Router do
  use CopmWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :graphql do
    plug :accepts, ["json"]
    plug CopmWeb.Plugs.RequireApiToken
  end

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :put_root_layout, html: {CopmWeb.Layouts, :root}
  end

  scope "/api" do
    pipe_through :graphql

    forward "/graphql", Absinthe.Plug,
      schema: CopmWeb.GraphQL.Schema

  end
  scope "/api", CopmWeb do
    pipe_through :api
  end

  scope "/", CopmWeb do
    pipe_through :browser
    get "/session/new", SessionController, :create
    live "/login", LoginLive
    live "/upload", UploadLive
  end
end
