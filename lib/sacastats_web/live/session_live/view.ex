defmodule SacaStatsWeb.SessionLive.View do
  @moduledoc """
  LiveView for viewing character sessions.
  """
  use SacaStatsWeb, :live_view
  use Phoenix.HTML

  alias Phoenix.PubSub
  alias SacaStats.Census.OnlineStatus
  alias SacaStats.{Characters, Session}

  require Logger

  def render(assigns) do
    Phoenix.View.render(SacaStatsWeb.CharacterView, "session.html", assigns)
  end

  def mount(
        %{"character_name" => name, "login_timestamp" => login_timestamp},
        _user_session,
        socket
      ) do
    %Session{} = session = Session.get(name, login_timestamp)

    {:ok, status} = OnlineStatus.get_by_id(session.character_id)

    PubSub.subscribe(SacaStats.PubSub, "game_event:#{session.character_id}")

    # Combine + sort events
    events =
      ([session.login] ++
         [session.logout] ++
         session.battle_rank_ups ++
         session.player_facility_captures ++
         session.player_facility_defends ++
         session.vehicle_destroys ++
         session.deaths ++
         session.gain_experiences)
      |> Enum.sort_by(fn event -> event.timestamp end, :desc)

    # Collect all unique character IDs
    all_character_ids =
      Enum.reduce(events, MapSet.new(), fn
        %{character_id: id, attacker_character_id: a_id}, mapset ->
          mapset
          |> MapSet.put(id)
          |> MapSet.put(a_id)

        %{character_id: id}, mapset ->
          MapSet.put(mapset, id)
      end)

    # "Preload" characters
    case Characters.get_many_by_id(all_character_ids, _shallow_copy = true) do
      {:ok, character_map} ->
        socket =
          socket
          |> assign(:character_info, %{
            "character_id" => session.character_id,
            "name" => %{"first" => session.name},
            "faction_id" => session.faction_id,
            "outfit" => session.outfit
          })
          |> assign(:online_status, status)
          |> assign(:events, events)
          |> assign(:character_map, character_map)
          |> assign(:stat_page, "session.html")
          |> assign(:session, session)

        {:ok, socket}

      :error ->
        {:ok,
         socket
         |> put_flash(
           :error,
           "We were unable to get that session right now, please try again later."
         )
         |> redirect(to: Routes.character_path(socket, :character, name, :sessions))}
    end
  end

  def handle_info(%Ecto.Changeset{} = event_cs, socket) do
    event = Ecto.Changeset.apply_changes(event_cs)

    events = socket.assigns.events
    character_map = socket.assigns.character_map

    # "Preload" the character names
    character_ids =
      event_cs.changes
      |> Map.take([:character_id, :attacker_character_id])
      |> Map.values()

    case Characters.get_many_by_id(character_ids, true) do
      {:ok, new_character_map} ->
        {:noreply,
         socket
         |> assign(:events, [event | events])
         |> assign(:character_map, Map.merge(character_map, new_character_map))}

      :error ->
        {:noreply,
         socket
         |> assign(:events, [event | events])
         |> put_flash(
           :error,
           "Tried to fetch character information for a new event, but something went wrong."
         )}
    end
  end
end
