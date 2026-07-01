defmodule CopmWeb.Router do
  use CopmWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", CopmWeb do
    pipe_through :api
  end
end
