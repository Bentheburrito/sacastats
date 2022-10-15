defmodule SacaStats.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias SacaStats.CensusCache.Fallbacks
  alias SacaStats.EventTracker

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      SacaStats.Repo,
      # Start the Telemetry supervisor
      SacaStatsWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: SacaStats.PubSub},
      # Start the Endpoint (http/https)
      SacaStatsWeb.Endpoint,
      # Start the SID manager
      SacaStats.SIDs,
      # Start caches
      Supervisor.child_spec(
        {SacaStats.CensusCache,
         [
           name: SacaStats.CharacterCache,
           fallback_fn: &Fallbacks.character/1,
           entry_expiration_ms: 60 * 60 * 1000
         ]},
        id: :character_cache
      ),
      Supervisor.child_spec(
        {SacaStats.CensusCache,
         [
           name: SacaStats.CharacterStatsCache,
           fallback_fn: &Fallbacks.character_stats/1,
           entry_expiration_ms: 2 * 60 * 60 * 1000
         ]},
        id: :character_stats_cache
      ),
      Supervisor.child_spec(
        {SacaStats.CensusCache,
         [
           name: SacaStats.OnlineStatusCache,
           fallback_fn: &Fallbacks.online_status/1,
           entry_expiration_ms: 12 * 60 * 60 * 1000
         ]},
        id: :online_status_cache
      ),
      Supervisor.child_spec(
        {SacaStats.CensusCache, [name: SacaStats.DiscordClientCache]},
        id: :discord_cache
      ),
      # Start the EventTracker Deduplicator
      {EventTracker.Deduper, []},
      # Start the EventTracker Manager
      {EventTracker.Manager, []},
      # Start the EventTracker Supervisor
      {EventTracker.Supervisor, []}
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
