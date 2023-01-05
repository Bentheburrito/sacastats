defmodule SacaStats.EventTracker.Deduper do
  @moduledoc """
  Responsible for deduplication of events that come in via multiple `EventTracker`s. `Deduper` will eventually insert a
  single instance of these duplicate events in the database, via batch inserts.

  The Deduper consumes events via `handle_event/1` and `Map.put_new/3`s them in an event map, where the key is an md5
  of the event payload, and the value is the event itself. After a configurable interval, `Deduper` will emit the
  dedup'd events (by default, the emitter fn is `SacaStats.Repo.insert/1`). Since it's possible that an event is be
  emitted before all duplicates are consumed, the event map is not cleared right away, and new events are put in a
  buffer map temporarily for a short time until we can be reasonably sure that any duplicates for the inserted events
  would be processed and discarded. After this short time, the events in the buffer map are flushed into the event map
  and normal operation is resumed.

  Note that there is a known shortcoming of this implementation: Since the `timestamp` field that ESS gives us on each
  event is accurate to the second, **any events that a player can trigger multiple times within a second will be dedup'd
  to one event.** In practice, this behavior is only observed for certain GainExperience events, like Vehicle Repair.
  """

  use GenServer

  alias Phoenix.PubSub
  alias SacaStats.EventTracker.Deduper
  alias SacaStats.Repo

  @default_emit_interval_ms 4 * 1000
  @default_buffer_interval_ms 1000

  defstruct event_map: %{},
            buffering?: false,
            buffer: %{},
            emitter: &Repo.insert/1,
            emit_interval_ms: @default_emit_interval_ms,
            buffer_interval_ms: @default_buffer_interval_ms

  @type t() :: %__MODULE__{
          event_map: map(),
          buffering?: boolean(),
          buffer: map(),
          emitter: (Ecto.Changeset.t() -> any),
          emit_interval_ms: integer(),
          buffer_interval_ms: integer()
        }

  ### API

  def start_link(opts) do
    opts = Keyword.put_new(opts, :name, __MODULE__)
    {emitter, opts} = Keyword.pop(opts, :emitter, &Repo.insert/1)
    {emit_interval, opts} = Keyword.pop(opts, :emit_interval_ms, @default_emit_interval_ms)
    {buffer_interval, opts} = Keyword.pop(opts, :buffer_interval_ms, @default_buffer_interval_ms)

    init_state = %Deduper{
      emitter: emitter,
      emit_interval_ms: emit_interval,
      buffer_interval_ms: buffer_interval
    }

    GenServer.start_link(__MODULE__, init_state, opts)
  end

  @spec handle_event(atom() | pid() | {atom(), any()} | {:via, atom(), any()}, any()) :: :ok
  def handle_event(deduper \\ __MODULE__, event) do
    # going to (perhaps naively) hash the entire event for now
    event_hash = :crypto.hash(:md5, inspect(event))
    GenServer.cast(deduper, {:handle_event, event_hash, event})
  end

  ### Impl

  @impl GenServer
  def init(%Deduper{} = state) do
    Process.send_after(self(), :emit_events, state.emit_interval_ms)
    {:ok, state}
  end

  @impl GenServer
  def handle_cast({:handle_event, event_hash, event}, %Deduper{} = state) do
    {:noreply, put_new_event(state, event_hash, event)}
  end

  @impl GenServer
  def handle_info(:emit_events, %Deduper{emitter: emitter} = state) do
    Task.start(fn ->
      Enum.each(state.event_map, fn {_hash, changeset} ->
        emitter.(changeset)
      end)
    end)

    Process.send_after(self(), :flush_buffer, state.buffer_interval_ms)

    {:noreply, %Deduper{buffering?: true}}
  end

  @impl GenServer
  def handle_info(:flush_buffer, %Deduper{} = state) do
    Process.send_after(self(), :emit_events, state.emit_interval_ms)

    {:noreply, %Deduper{event_map: state.buffer, buffering?: false, buffer: %{}}}
  end

  @doc """
  Puts `event` under `hash` in either the `event_map` or `buffer` maps of a %Deduper{}`, depending on the value of
  `buffering?`.

  If `buffering?` is `false`, `event` will be put under `hash` in `event_map`, unless an entry under `hash` already
  exists in `event_map`.

  If `buffering?` is `true`, `event` will be put under `hash` in `buffer`, unless an entry under `hash` already exists
  in `event_map` OR `buffer`.
  """
  @spec put_new_event(t(), any(), any()) :: t()
  def put_new_event(%Deduper{buffering?: false} = state, hash, event) do
    %Deduper{state | event_map: put_new_and_broadcast(state.event_map, hash, event)}
  end

  # buffering?: true from now on
  def put_new_event(%Deduper{event_map: map} = state, hash, _event) when is_map_key(map, hash) do
    state
  end

  def put_new_event(%Deduper{} = state, hash, event) do
    %Deduper{state | buffer: put_new_and_broadcast(state.buffer, hash, event)}
  end

  defp put_new_and_broadcast(map, hash, %Ecto.Changeset{} = event) do
    if is_map_key(map, hash) do
      map
    else
      if is_map_key(event.changes, :character_id) do
        PubSub.broadcast(SacaStats.PubSub, "game_event:#{event.changes.character_id}", event)
      end

      if is_map_key(event.changes, :attacker_character_id) do
        PubSub.broadcast(
          SacaStats.PubSub,
          "game_event:#{event.changes.attacker_character_id}",
          event
        )
      end

      if is_map_key(event.changes, :other_id) do
        PubSub.broadcast(
          SacaStats.PubSub,
          "game_event:#{event.changes.other_id}",
          event
        )
      end

      event_name = event.data.__struct__ |> Module.split() |> List.last()
      PubSub.broadcast(SacaStats.PubSub, "game_event:#{event_name}", event)

      Map.put(map, hash, event)
    end
  end
end
