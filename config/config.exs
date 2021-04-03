# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :planetside_api, service_id: System.get_env("SERVICE_ID")

config :sacastats,
  namespace: SacaStats,
  ecto_repos: [SacaStats.Repo]

# Configures the endpoint
config :sacastats, SacaStatsWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "bfZqAptRN1BzITOLDo0BsZpgVc6GVrjsJvAW9sn/YmOgkobM9Lx6D/EA9nAv0bUR",
  render_errors: [view: SacaStatsWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: SacaStats.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
