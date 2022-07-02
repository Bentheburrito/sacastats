defmodule SacaStats.EventTracker do
  @moduledoc """
  Handles events received from ESS, persisting them to the DB, and broadcasting them.
  """

  use GenServer

  @behaviour PS2.SocketClient

  require Logger

  alias Phoenix.PubSub
  alias SacaStats.{Events, Repo}
  alias SacaStats.EventTracker.Report

  @impl PS2.SocketClient
  def handle_event({event_name, payload}) do
    {:ok, event_changeset} = Events.cast_event(event_name, payload)

    PubSub.broadcast(SacaStats.PubSub, event_name, event_changeset)

    # case Repo.insert(event_changeset) do
    #   {:ok, _} -> nil
    #   {:error, _} -> Logger.info("Discarded duplicate event for #{event_name}")
    # end
  end

  ### API

  @impl PS2.SocketClient
  def handle_event(_event), do: nil

  def start_link(opts) when is_list(opts) do
    GenServer.start_link(__MODULE__, %Report{}, opts)
  end

  def pop_report(pid) do
    GenServer.call(pid, :pop_report)
  end

  ### Impl

  @impl GenServer
  def init(init_state) do
    {:ok, init_state}
  end

  @impl GenServer
  def handle_call(:pop_report, _from, %Report{} = report) do
    {:reply, report, %Report{}}
  end
end
