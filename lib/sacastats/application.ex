defmodule SacaStats.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias SacaStats.CensusCache.Fallbacks

  @impl true
  def start(_type, _args) do
    ess_opts = [
      subscriptions: SacaStats.ess_subscriptions(),
      clients: [SacaStats.EventTracker],
      service_id: SacaStats.sid()
    ]

    # Start session ETS table.
    :ets.new(:session, [:named_table, :public, read_concurrency: true])

    children = [
      # Start the Ecto repository
      SacaStats.Repo,
      # Start the Telemetry supervisor
      SacaStatsWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: SacaStats.PubSub},
      # Start the Endpoint (http/https)
      SacaStatsWeb.Endpoint,
      # Start caches
      Supervisor.child_spec(
        {SacaStats.CensusCache,
         [name: SacaStats.CharacterCache, fallback_fn: &Fallbacks.character/1]},
        id: :character_cache
      ),
      Supervisor.child_spec(
        {SacaStats.CensusCache,
         [name: SacaStats.OnlineStatusCache, fallback_fn: &Fallbacks.online_status/1]},
        id: :online_status_cache
      ),
      Supervisor.child_spec(
        {SacaStats.CensusCache,
         [name: SacaStats.DiscordClientCache, fallback_fn: fn _ -> :not_found end]},
        id: :discord_cache
      ),
      # Start the ESS Websocket
      {PS2.Socket, ess_opts}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: SacaStats.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    SacaStatsWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
