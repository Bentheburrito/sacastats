defmodule SacaStats.EventTracker do
  @moduledoc """
  Handles events received from ESS, persisting them to the DB, and broadcasting them.
  """

  use GenServer

  @behaviour PS2.SocketClient

  require Logger

  alias Phoenix.PubSub
  alias SacaStats.Events
  alias SacaStats.EventTracker.{Deduper, Report}

  @impl PS2.SocketClient
  def handle_event({event_name, payload}, event_tracker_pid: pid) do
    {:ok, event_changeset} = Events.cast_event(event_name, payload)

    PubSub.broadcast(SacaStats.PubSub, event_name, event_changeset)
    Deduper.handle_event(event_changeset)
    log_event(pid, event_name)
  end

  ### API

  @impl PS2.SocketClient
  def handle_event(_event), do: nil

  def start_link(opts) when is_list(opts) do
    GenServer.start_link(__MODULE__, nil, opts)
  end

  def log_event(pid, event_name) do
    GenServer.cast(pid, {:log_event, event_name})
  end

  def pop_report(pid) do
    GenServer.call(pid, :pop_report)
  end

  ### Impl

  @impl GenServer
  def init(_init_state) do
    service_id = SacaStats.SIDs.next()

    PS2.Socket.start_link(
      subscriptions: SacaStats.ess_subscriptions(),
      clients: [SacaStats.EventTracker],
      service_id: service_id,
      name: :none,
      metadata: [event_tracker_pid: self()]
    )

    {:ok, %Report{event_tracker_pid: self(), service_id: service_id}}
  end

  @impl GenServer
  def handle_cast({:log_event, event_name}, %Report{} = report) do
    event_counts = Map.update(report.event_counts, event_name, 1, &(&1 + 1))
    {:noreply, %Report{report | event_counts: event_counts}}
  end

  @impl GenServer
  def handle_call(:pop_report, _from, %Report{} = report) do
    {:reply, report, %Report{event_tracker_pid: self(), service_id: report.service_id}}
  end
end
