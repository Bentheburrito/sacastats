defmodule SacaStats.EventTracker do
  @moduledoc """
  Handles events received from ESS, persisting them to the DB, and broadcasting them.
  """

  @behaviour PS2.SocketClient

  require Logger

  alias Phoenix.PubSub
  alias SacaStats.{Events, Repo}

  @impl PS2.SocketClient
  def handle_event({event_name, payload}) do
    {:ok, event_changeset} = Events.cast_event(event_name, payload)

    PubSub.broadcast(SacaStats.PubSub, event_name, event_changeset)

    case Repo.insert(event_changeset) do
      {:ok, _} -> nil
      {:error, _} -> Logger.info("Discarded duplicate event for #{event_name}")
    end
  end

  # Catch-all callback.
  @impl PS2.SocketClient
  def handle_event(_event), do: nil
end
