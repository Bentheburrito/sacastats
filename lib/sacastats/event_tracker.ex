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
    {:ok, event} = Events.cast_event(event_name, payload)

    PubSub.broadcast(SacaStats.PubSub, event_name, event)
    Repo.insert!(event)
  end

  # Catch-all callback.
  @impl PS2.SocketClient
  def handle_event(_event), do: nil
end
