# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :sacastats,
  namespace: SacaStats,
  ecto_repos: [SacaStats.Repo]

# Configures the endpoint
config :sacastats, SacaStatsWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "RXaV6C6W9mFyY5gijphdcw2Mrn+0CoFF7ytapN3bAqG3iZyaCMP7WvOftTAxlwIQ",
  render_errors: [view: SacaStatsWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: SacaStats.PubSub,
  live_view: [signing_salt: "cUBGyO85"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
