defmodule SacaStatsWeb.SessionLive.View do
  @moduledoc """
  LiveView for viewing character sessions.
  """
  use SacaStatsWeb, :live_view
  use Phoenix.HTML

  alias Phoenix.PubSub
  alias SacaStats.Census.Character
  alias SacaStats.Census.OnlineStatus
  alias SacaStats.Character.Favorite
  alias SacaStats.{Characters, Session}

  require Logger

  def render(assigns) do
    Phoenix.View.render(SacaStatsWeb.CharacterView, "template.html", assigns)
  end

  def handle_params(_unsigned_params, uri, socket),
    do: {:noreply, assign(socket, request_path: URI.parse(uri).path)}

  def mount(
        %{"character_name" => name, "login_timestamp" => login_timestamp},
        user_session,
        socket
      ) do
    %Session{} = session = Session.get(name, login_timestamp)

    {:ok, status} = OnlineStatus.get_by_id(session.character_id)

    # If connected, this is the 2nd mount call/LiveView init
    if connected?(socket) do
      PubSub.subscribe(SacaStats.PubSub, "game_event:#{session.character_id}")

      # In order to load the page quickly, we do the expensive Event Log-related things in another task, and send a
      # message to the LiveView process after the page loads.
      liveview_pid = self()

      Task.start_link(fn -> do_mount(session, name, liveview_pid) end)
    end

    user = user_session["user"] || user_session[:user]
    user_id = if is_nil(user), do: nil, else: user.id

    {:ok,
     socket
     |> assign(:character_info, %Character{
       character_id: session.character_id,
       name_first: session.name,
       faction_id: session.faction_id,
       outfit: session.outfit,
       last_save: System.os_time(:second)
     })
     |> assign(:online_status, OnlineStatus.status_text(status))
     |> assign(:events, :loading)
     |> assign(:stat_page, "session.html")
     |> assign(:request_path, nil)
     |> assign(:conn, socket)
     |> assign(:character_map, :loading)
     |> assign(:session, session)
     |> assign(:user, user_session["user"] || user_session[:user])
     |> assign(is_favorite: Characters.favorite?(session.character_id, user_id))
     |> assign(changeset: Favorite.changeset(%Favorite{}))}
  end

  defp do_mount(session, name, liveview_pid) do
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

        %{character_id: id, other_id: o_id}, mapset ->
          mapset
          |> MapSet.put(id)
          |> MapSet.put(o_id)

        %{character_id: id}, mapset ->
          MapSet.put(mapset, id)
      end)

    # "Preload" characters
    case Characters.get_many_by_id(all_character_ids, _shallow_copy = true) do
      {:ok, character_map} ->
        send(liveview_pid, {:update_expensive, events, character_map})

      :error ->
        Logger.error("Could not fetch many character IDs: #{inspect(all_character_ids)}")

        send(
          liveview_pid,
          {:error, name, "We were unable to get that session right now, please try again later."}
        )
    end
  end

  # New event arrives
  def handle_info(%Ecto.Changeset{} = event_cs, socket) do
    event = Ecto.Changeset.apply_changes(event_cs)

    events = socket.assigns.events
    character_map = socket.assigns.character_map

    # update the aggregate counts
    new_session = Session.aggregate(socket.assigns.session, [[event]])

    socket =
      socket
      |> assign(:events, [event | events])
      |> assign(:session, new_session)

    # "Preload" any new character IDs
    character_ids =
      event_cs.changes
      |> Map.take([:character_id, :attacker_character_id, :other_id])
      |> Map.values()
      |> Enum.reject(&(&1 == socket.assigns.session.character_id))

    if length(character_ids) > 0 do
      case Characters.get_many_by_id(character_ids, _shallow_copy = true) do
        {:ok, new_character_map} ->
          {:noreply, assign(socket, :character_map, Map.merge(character_map, new_character_map))}

        :error ->
          {:noreply,
           put_flash(
             socket,
             :error,
             "Tried to fetch character information for a new event, but something went wrong."
           )}
      end
    else
      {:noreply, socket}
    end
  end

  # Event and character map results
  def handle_info({:update_expensive, events, character_map}, socket) do
    {:noreply,
     socket
     |> assign(:events, events)
     |> assign(:character_map, character_map)}
  end

  # Event and character map calculations failed
  def handle_info({:error, character_name, reason}, socket) do
    {:noreply,
     socket
     |> put_flash(:error, reason)
     |> redirect(to: Routes.character_path(socket, :character, character_name, :sessions))}
  end
end
