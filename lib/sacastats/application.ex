defmodule SacaStats.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

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
      Supervisor.child_spec({Cachex, name: :character_cache}, id: :character_cache),
      Supervisor.child_spec({Cachex, name: :online_status_cache}, id: :online_status_cache),
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
