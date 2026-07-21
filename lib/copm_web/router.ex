defmodule CopmWeb.Router do
  use CopmWeb, :router


  pipeline :ingest do
    plug :accepts, ["json"]
    plug CopmWeb.DataProviderCheck
  end

  pipeline :openapi do
    plug :accepts, ["json"]
    plug OpenApiSpex.Plug.PutApiSpec, module: CopmWeb.ApiSpec
  end
  pipeline :graphql do
    plug :accepts, ["json"]
    plug CopmWeb.Plugs.GenGraphQlContext
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
    pipe_through :ingest
    post "/ingest/csv", IngestController, :create_file
    post "/ingest/:topic", IngestController, :create
    get "/ingest/listtrans", ListOrgTransactions, :show_transact
    get "/ingest/batches/:id", BatchController, :show_batch
    get "/ingest/:topic/:id", IngestController, :show
  end

  scope "/api" do
    pipe_through :openapi
    get "/openapi", OpenApiSpex.Plug.RenderSpec, []
  end

  scope "/" do
    pipe_through :openapi
    get "/swaggerui", OpenApiSpex.Plug.SwaggerUI, path: "/api/openapi"
  end

  scope "/", CopmWeb do
    pipe_through :browser
    get "/", RedirectToLogin, :redirect_to_login
    get "/session/new", SessionController, :create
    get "/logout", LogoutController, :delete
    live "/login", LoginLive
    live "/admin/operators", OperatorLive
    live "/admin/operators/new", OperatorFormLive, :new
    live "/admin/operators/:id/edit", OperatorFormLive, :edit
    live "/admin/orgs", OrgLive
    live "/admin/orgs/new", OrgFormLive, :new
  end
end
