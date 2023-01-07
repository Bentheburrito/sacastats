defmodule SacaStats.WorldTracker do
  @moduledoc """
  A GenServer that subscribes to events related to world state, populations, and metagame events.

  Currently, it just receives PlayerLogin/Logout events and updates :online_status_cache.
  """
  use GenServer

  alias Phoenix.PubSub
  alias SacaStats.Census.OnlineStatus
  alias SacaStats.Events.{PlayerLogin, PlayerLogout}

  ## Client

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil)
  end

  ## Impl

  @impl true
  def init(_) do
    PubSub.subscribe(SacaStats.PubSub, "game_event:PlayerLogin")
    PubSub.subscribe(SacaStats.PubSub, "game_event:PlayerLogout")
    {:ok, nil}
  end

  @impl true
  def handle_info(%Ecto.Changeset{} = event_cs, state) do
    new_state =
      event_cs
      |> Ecto.Changeset.apply_changes()
      |> handle_event(state)

    {:noreply, new_state}
  end

  defp handle_event(%PlayerLogin{} = login, state) do
    status_params = %{"character_id" => login.character_id, "online_status" => 1}

    status =
      %OnlineStatus{}
      |> OnlineStatus.changeset(status_params)
      |> Ecto.Changeset.apply_changes()

    Cachex.put(:online_status_cache, status.character_id, status, OnlineStatus.put_opts())

    state
  end

  defp handle_event(%PlayerLogout{} = logout, state) do
    status_params = %{"character_id" => logout.character_id, "online_status" => 0}

    status =
      %OnlineStatus{}
      |> OnlineStatus.changeset(status_params)
      |> Ecto.Changeset.apply_changes()

    Cachex.put(:online_status_cache, status.character_id, status, OnlineStatus.put_opts())

    state
  end
end
