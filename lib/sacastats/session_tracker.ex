defmodule SacaStats.SessionTracker do
  @max_seconds_unarchived 1.5 * 60 * 60
  @max_ids_to_fetch 200
  @logout_diff_margin_seconds 3
  @archive_interval_seconds 20
  @new_sessions_interval_seconds 30

  @moduledoc """
  A GenServer that tracks Planetside character sessions.

  A session is an aggregation of the events related to a character that took place between
  the player's login and logout time. A session can be active (player is currently logged in) or
  closed (player has logged out.) A closed session can be archived or unarchived. See the
  [Archived Sessions](#archived-sessions) section below to read more.

  ## New Sessions
  When a player logs in, ESS only gives us their character ID and timestamp. We have to fetch other
  data like `faction_id` from the Census. Instead of hitting the census every time a player logs
  in, we accumulate character IDs in a queue, and get the info all at once on an interval of
  #{@new_sessions_interval_seconds} seconds.

  ## Archived Sessions
  Some data that SacaStats tracks is not immediately obtainable after a session is closed, namely
  the `shots_fired` and `shots_hit` fields. These fields are obtained from the Census, and when
  a player logs out, the census does not update immediately (values have been observed to update up
  to an hour after the log out.) So, we call sessions that are closed but don't yet have these
  data points "unarchived." We check the API for the updates on an interval of #{@archive_interval_seconds}
  seconds.
  """
  use GenServer
  require Logger

  import Ecto.Query
  import PS2.API.QueryBuilder

  alias Ecto.Changeset
  alias PS2.API.{Join, Query, QueryResult}
  alias SacaStats.CharacterSession
  alias SacaStats.Repo

  ### API ###
  def start_link(init_state) do
    GenServer.start_link(__MODULE__, init_state, name: __MODULE__)
  end

  def put(character_id, login_timestamp) do
    changeset =
      CharacterSession.changeset(%CharacterSession{}, %{
        character_id: character_id,
        login_timestamp: login_timestamp
      })

    if changeset.valid? do
      session = Changeset.apply_changes(changeset)
      GenServer.call(__MODULE__, {:put, session})
    else
      {:errors, changeset.errors}
    end
  end

  @spec get(character_id :: integer() | String.t()) :: {:ok, CharacterSession.t()} | :error
  def get(character_id) when is_binary(character_id) do
    character_id |> String.to_integer() |> get()
  end

  def get(character_id) do
    GenServer.call(__MODULE__, {:get, character_id})
  end

  def find(limit \\ :infinity, fun) do
    GenServer.call(__MODULE__, {:find, limit, fun})
  end

  def update(%Changeset{} = changeset) do
    if changeset.valid? do
      session = Changeset.apply_changes(changeset)
      GenServer.call(__MODULE__, {:update, session})
    else
      {:errors, changeset.errors}
    end
  end

  def close(character_id, logout_timestamp) when is_binary(character_id) do
    close(String.to_integer(character_id), logout_timestamp)
  end

  def close(character_id, logout_timestamp) do
    GenServer.cast(__MODULE__, {:close, character_id, logout_timestamp})
  end

  ### Impl ###
  def init(state) do
    schedule_work()
    {:ok, state}
  end

  def handle_call(
        {:put, %CharacterSession{character_id: character_id} = session},
        _from,
        {session_map, pending_ids}
      ) do
    {:reply, :ok, {Map.put(session_map, character_id, session), [character_id | pending_ids]}}
  end

  def handle_call({:get, character_id}, _from, {session_map, pending_ids}) do
    {:reply, Map.fetch(session_map, character_id), {session_map, pending_ids}}
  end

  def handle_call({:find, limit, fun}, _from, {session_map, pending_ids}) do
    sessions =
      session_map
      |> Enum.map(fn {_char_id, session} -> session end)
      |> Enum.filter(fun)
      |> then(
        &if is_integer(limit) do
          Enum.take(&1, limit)
        else
          &1
        end
      )

    {:reply, sessions, {session_map, pending_ids}}
  end

  def handle_call(
        {:update, %CharacterSession{character_id: character_id} = session},
        _from,
        {session_map, pending_ids}
      ) do
    {:reply, :ok, {Map.put(session_map, character_id, session), pending_ids}}
  end

  def handle_cast({:close, character_id, logout_timestamp}, {session_map, pending_ids}) do
    with {:ok, %CharacterSession{xp_earned: xp} = session} when xp > 0 <-
           Map.fetch(session_map, character_id),
         changeset <- CharacterSession.changeset(session, %{logout_timestamp: logout_timestamp}),
         {:ok, %CharacterSession{character_id: id}} <- Repo.insert(changeset) do
      Logger.debug("Saved session to db: #{id}")
    else
      {:ok, %CharacterSession{}} ->
        Logger.debug("Not saving session with 0 xp: #{character_id}")

      :error ->
        Logger.debug("Can't close session [doesn't exist]: #{character_id}")

      {:error, changeset} ->
        Logger.error("Could not save session to db: #{inspect(changeset.errors)}")
    end

    {:noreply, {Map.delete(session_map, character_id), List.delete(pending_ids, character_id)}}
  end

  ### New sessions ###
  def handle_info({:fetch_new_sessions, :start}, {_session_map, queue} = state)
      when queue == [] do
    schedule_work(:new_sessions)
    {:noreply, state}
  end

  def handle_info({:fetch_new_sessions, :start}, {session_map, pending_ids}) do
    {to_fetch, remaining_ids} = Enum.split(pending_ids, @max_ids_to_fetch)

    Task.start(fn ->
      result = fetch_char_list(to_fetch)
      send(__MODULE__, {:fetch_new_sessions, :finish, result})
    end)

    {:noreply, {session_map, remaining_ids}}
  end

  def handle_info(
        {:fetch_new_sessions, :finish, {char_list, remaining_pending_ids}},
        {session_map, pending_ids}
      ) do
    new_session_map = char_list_to_sessions(char_list, session_map)
    schedule_work(:new_sessions)
    {:noreply, {new_session_map, pending_ids ++ remaining_pending_ids}}
  end

  ### (Un)archived sessions ###
  def handle_info({:archive_sessions, :start}, state) do
    Task.start(fn ->
      unarchived_sessions =
        SacaStats.Repo.all(
          from(s in SacaStats.CharacterSession,
            select: s,
            where: s.archived == false,
            limit: @max_ids_to_fetch
          )
        )

      {char_list, _remaining_pending_ids} =
        fetch_char_list(Enum.map(unarchived_sessions, & &1.character_id))

      # Data checks: body.returned should equal rows.length. If not, find char IDs that are missing from the Census,
      # and remove them from DB (js behavior) OR just set them as archived.
      send(__MODULE__, {:archive_sessions, :finish, {char_list, unarchived_sessions}})
    end)

    {:noreply, state}
  end

  def handle_info(
        {:archive_sessions, :finish, {char_list, unarchived_sessions}},
        state
      ) do
    num_archived = archive_sessions(unarchived_sessions, char_list)

    Logger.debug("Archived #{num_archived} sessions.")

    schedule_work(:archive_sessions)
    {:noreply, state}
  end

  # Still need to check if some characters are missing (in the case of new characters)
  defp fetch_char_list([]), do: {[], []}

  defp fetch_char_list(character_ids) do
    char_query =
      Query.new(collection: "character")
      |> term("character_id", Enum.join(character_ids, ","))
      |> show(["character_id", "faction_id", "name", "times.last_save"])
      |> join(
        Join.new(collection: "characters_world")
        |> inject_at("world")
        |> show("world_id")
      )
      |> join(
        Join.new(collection: "characters_weapon_stat")
        |> list(true)
        |> inject_at("weapon_shot_stats")
        |> show(["stat_name", "item_id", "vehicle_id", "value"])
        |> term("stat_name", ["weapon_hit_count", "weapon_fire_count"])
        |> term("vehicle_id", "0")
        |> term("item_id", "0", :not)
        |> join(
          Join.new(collection: "item")
          |> inject_at("weapon")
          |> outer(false)
          |> show(["name.en", "item_category_id"])
          |> term("item_category_id", ["3", "5", "6", "7", "8", "12", "19", "24", "100", "102"])
        )
      )

    case PS2.API.query(char_query, SacaStats.sid()) do
      {:ok, %QueryResult{data: char_list}} ->
        {char_list, []}

      {:error, %HTTPoison.Error{reason: reason}} when reason in [:timeout, :closed] ->
        Logger.warn(
          "SessionTracker.fetch_char_list/1 query failed with reason #{reason}, retrying..."
        )

        fetch_char_list(character_ids)

      # Likely a timeout or other random error from the API.
      {:error, error} ->
        Logger.error(inspect(error))
        {[], character_ids}

      # Unexpected error, discard the character_ids.
      e ->
        Logger.error("UNEXPECTED ERROR in SessionTracker.fetch_char_list/1: #{inspect(e)}")
        {[], []}
    end
  end

  defp char_list_to_sessions([], session_map), do: session_map

  defp char_list_to_sessions(char_list, session_map) do
    Enum.reduce(char_list, session_map, fn
      %{
        "character_id" => character_id_str,
        "name" => %{"first" => name},
        "faction_id" => faction_id,
        "world" => %{"world_id" => world_id}
      } = char,
      sessions ->
        with character_id <- String.to_integer(character_id_str),
             {:ok, session} <- Map.fetch(sessions, character_id) do
          {fire_count, hit_count} = count_weapon_stats(Map.get(char, "weapon_shot_stats", %{}))

          params = %{
            "name" => name,
            "faction_id" => faction_id,
            "shots_fired" => fire_count,
            "shots_hit" => hit_count
          }

          changeset = CharacterSession.changeset(session, params)

          if changeset.valid? do
            # SacaStats.WorldState.add_population(world_id, faction_id, 1)
            session = Changeset.apply_changes(changeset)
            Map.put(sessions, character_id, session)
          else
            sessions
          end
        else
          :error -> sessions
        end

      _, sessions ->
        sessions
    end)
  end

  defp count_weapon_stats(stat_map) when stat_map == %{}, do: {0, 0}

  defp count_weapon_stats(stat_map) do
    Enum.reduce(stat_map, {0, 0}, fn
      %{"stat_name" => "weapon_fire_count", "value" => val}, {fire_count, hit_count} ->
        {fire_count + String.to_integer(val), hit_count}

      %{"stat_name" => "weapon_hit_count", "value" => val}, {fire_count, hit_count} ->
        {fire_count, hit_count + String.to_integer(val)}

      _, {fire_count, hit_count} ->
        {fire_count, hit_count}
    end)
  end

  defp schedule_work(:new_sessions) do
    Process.send_after(
      self(),
      {:fetch_new_sessions, :start},
      @new_sessions_interval_seconds * 1000
    )
  end

  defp schedule_work(:archive_sessions),
    do: Process.send_after(self(), {:archive_sessions, :start}, @archive_interval_seconds * 1000)

  defp schedule_work do
    schedule_work(:new_sessions)
    schedule_work(:archive_sessions)
  end

  @doc """
  Checks if the given unix timestamps are within #{@logout_diff_margin_seconds} seconds of each other.
  """
  defp timestamps_match?(ts1, ts2) do
    ts_diff = ts1 - ts2
    (ts_diff - -@logout_diff_margin_seconds) * (ts_diff - @logout_diff_margin_seconds) <= 0
  end

  defp archive_sessions(unarchived, char_list) do
    Enum.reduce(unarchived, 0, fn session, num_archived ->
      with {:ok, character} <- get_character_from_list(char_list, session.character_id),
           true <- maybe_archive_session(character, session) do
        num_archived + 1
      else
        _ -> num_archived
      end
    end)
  end

  defp get_character_from_list(char_list, character_id) do
    case Enum.find(char_list, &(String.to_integer(&1["character_id"]) == character_id)) do
      nil -> :none
      session -> {:ok, session}
    end
  end

  defp maybe_archive_session(character, %CharacterSession{} = session) do
    census_logout_ts = String.to_integer(character["times"]["last_save"])

    params =
      cond do
        # If the logout_timestamp the Census returns matches the logout time given by ESS, set the difference
        # of shot stats and archive the session.
        timestamps_match?(census_logout_ts, session.logout_timestamp) ->
          {end_fire_count, end_hit_count} =
            count_weapon_stats(Map.get(character, "weapon_shot_stats", %{}))

          Logger.debug(
            "Census updated session (id: #{session.id}). fired: #{end_fire_count}, #{session.shots_fired}, " <>
              "hit: #{end_hit_count}, #{session.shots_hit}"
          )

          %{
            "shots_fired" => end_fire_count - session.shots_fired,
            "shots_hit" => end_hit_count - session.shots_hit,
            "archived" => true
          }

        # If the Census gives us a later logout timestamp, we've missed the update, zero out shot stats and archive.
        census_logout_ts > session.logout_timestamp ->
          Logger.debug(
            "Census logout ts > session logout ts by #{census_logout_ts - session.logout_timestamp} " <>
              "seconds, archiving session (id: #{session.id}) with zero'd shot stats"
          )

          %{
            "shots_fired" => 0,
            "shots_hit" => 0,
            "archived" => true
          }

        # If the session has been unarchived for too long, assume the Census update isn't happening, so
        # zero out shot stats and archive.
        System.os_time(:second) > session.logout_timestamp + @max_seconds_unarchived ->
          Logger.debug(
            "Session (id: #{session.id}) has been unarchived for more than " <>
              "#{@max_seconds_unarchived} seconds, archiving with zero'd shot stats"
          )

          %{
            "shots_fired" => 0,
            "shots_hit" => 0,
            "archived" => true
          }

        # else, update nothing
        true ->
          %{}
      end

    # Update the session, and return its new archive status
    session |> CharacterSession.changeset(params) |> SacaStats.Repo.update()
    Map.get(params, "archived", false)
  end
end
