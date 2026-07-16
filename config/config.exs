# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :copm,
  ecto_repos: [Copm.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configure the endpoint
config :copm, CopmWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: CopmWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Copm.PubSub,
  live_view: [signing_salt: "6l60jh4y"]

# Configure Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason


config :copm,
  kafka_hosts: [{"localhost", 9092}],
  refresh_token_ttl: 30* 24 * 60 * 60,
  access_token_ttl: 15 * 60
# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
