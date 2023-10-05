defmodule SacaStats.Session do
  @moduledoc """
  Struct representing a character session. The data is populated from raw events stored in the DB. Use the functions in
  this module to build session structs for given character IDs and timestamps.
  """

  alias SacaStats.Census.Character
  alias SacaStats.Events.BattleRankUp
  alias SacaStats.Events.PlayerFacilityCapture
  alias SacaStats.Events.PlayerFacilityDefend
  alias SacaStats.{Characters, Events, Repo, Session}

  import Ecto.Query
  import SacaStats.Utils, only: [typedstruct: 1, bool_to_int: 1]

  require Logger

  typedstruct do
    field :character_id, integer(), required?: true
    field :faction_id, integer()
    field :name, String.t()
    field :outfit, Map.t()
    # aggregate data
    field :kill_count, integer(), default: 0
    field :kill_hs_count, integer(), default: 0
    field :kill_hs_ivi_count, integer(), default: 0
    field :kill_ivi_count, integer(), default: 0
    field :death_ivi_count, integer(), default: 0
    field :death_count, integer(), default: 0
    field :revive_count, integer(), default: 0
    field :vehicle_kill_count, integer(), default: 0
    field :vehicle_death_count, integer(), default: 0
    field :nanites_destroyed, integer(), default: 0
    field :nanites_lost, integer(), default: 0
    field :xp_earned, integer(), default: 0
    # raw data
    field :battle_rank_ups, Events.BattleRankUp.t()
    field :deaths, Events.Death.t()
    field :gain_experiences, Events.GainExperience.t()
    field :player_facility_captures, Events.PlayerFacilityCaptures.t()
    field :player_facility_defends, Events.PlayerFacilityDefend.t()
    field :vehicle_destroys, Events.VehicleDestroy.t()
    field :login, Events.PlayerLogin.t()
    field :logout, Events.PlayerLogout.t()
  end

  @doc """
  Gets latest timestamp from of all a character's sessions.
  """
  def get_latest_timestamp(character_id) do
    Repo.one(
      from login in Events.PlayerLogin,
        where: login.character_id == ^character_id,
        order_by: [desc: :timestamp],
        limit: 1
    )
  end

  @doc """
  Gets a summary of all a character's sessions. This function is similar to `get_all/1`, except it does not fetch events
  (besides PlayerLogins and PlayerLogouts), and does not calculate aggregations. Therefore, this function is useful
  for seeing session durations and start/end times at a glance, when specific session data is not needed yet.
  """
  def get_summary(character_name) do
    {:ok, %Character{character_id: character_id} = char} = Characters.get_by_name(character_name)

    logins =
      Repo.all(
        from login in Events.PlayerLogin,
          where: login.character_id == ^character_id,
          order_by: [desc: :timestamp]
      )

    logouts =
      Repo.all(
        from logout in Events.PlayerLogout,
          where: logout.character_id == ^character_id,
          order_by: [desc: :timestamp]
      )

    latest_login = List.first(logins)
    latest_logout = List.first(logouts)

    # If this character is currently online/has a session open, then their most recent login will be more
    # recent than their most recent logout. So we should add a map with a timestamp field that tells us just that.
    logouts =
      cond do
        # If this character hasn't logged in before, do nothing with logouts
        is_nil(latest_login) ->
          logouts

        # If this character has logged in at least once, but has never logged out, they are currently online and this
        # is their first recorded session. Or, if their latest login > latest logout, they are currently online. Either
        # way, mark the latest logout as an active session.
        (not is_nil(latest_login) and is_nil(latest_logout)) or
            latest_login.timestamp > latest_logout.timestamp ->
          [%{timestamp: :current_session, character_id: character_id} | logouts]

        :else ->
          logouts
      end

    logins
    |> Stream.zip(logouts)
    |> Stream.map(fn {login, logout} ->
      %Session{
        character_id: character_id,
        faction_id: char.faction_id,
        name: char.name_first,
        login: login,
        logout: logout
      }
    end)
    |> Enum.to_list()
  end

  def get_all(character_name) do
    {:ok, %Character{character_id: character_id} = char} = Characters.get_by_name(character_name)

    character_id = SacaStats.Utils.maybe_to_int(character_id, 0)

    where_clause = [character_id: character_id]

    attack_where_clause =
      dynamic(
        [e],
        field(e, :character_id) == ^character_id or
          field(e, :attacker_character_id) == ^character_id
      )

    revive_xp_ids = SacaStats.revive_xp_ids()

    # Considers GE revive events where other_id is this character (i.e., this character was revived by someone else)
    ge_where_clause =
      dynamic(
        [e],
        field(e, :character_id) == ^character_id or
          (field(e, :other_id) == ^character_id and
             field(e, :experience_id) in ^revive_xp_ids)
      )

    all_br_ups = Repo.all(gen_session_events_query(Events.BattleRankUp, where_clause))
    all_deaths = Repo.all(gen_session_events_query(Events.Death, attack_where_clause))
    all_gain_xp = Repo.all(gen_session_events_query(Events.GainExperience, ge_where_clause))

    all_facility_caps =
      Repo.all(gen_session_events_query(Events.PlayerFacilityCapture, where_clause))

    all_facility_defs =
      Repo.all(gen_session_events_query(Events.PlayerFacilityDefend, where_clause))

    all_vehicle_destroys =
      Repo.all(gen_session_events_query(Events.VehicleDestroy, attack_where_clause))

    logins =
      Repo.all(
        from login in Events.PlayerLogin,
          where: login.character_id == ^character_id,
          order_by: [desc: :timestamp]
      )

    logouts =
      Repo.all(
        from logout in Events.PlayerLogout,
          where: logout.character_id == ^character_id,
          order_by: [desc: :timestamp]
      )

    latest_login = List.first(logins)
    latest_logout = List.first(logouts)

    # If this character is currently online/has a session open, then their most recent login will be more
    # recent than their most recent logout. So we should add a map with a timestamp field that tells us just that.
    logouts =
      cond do
        is_nil(latest_login) or is_nil(latest_logout) ->
          logouts

        latest_login.timestamp > latest_logout.timestamp ->
          [%{timestamp: :current_session, character_id: character_id} | logouts]

        :else ->
          logouts
      end

    logins
    |> Stream.zip(logouts)
    |> Stream.map(fn {login, logout} ->
      event_in_session? = &(&1.timestamp in login.timestamp..logout.timestamp)

      br_ups = Enum.filter(all_br_ups, event_in_session?)
      deaths = Enum.filter(all_deaths, event_in_session?)
      gain_xp = Enum.filter(all_gain_xp, event_in_session?)
      facility_caps = Enum.filter(all_facility_caps, event_in_session?)
      facility_defs = Enum.filter(all_facility_defs, event_in_session?)
      vehicle_destroys = Enum.filter(all_vehicle_destroys, event_in_session?)

      %Session{} = session = aggregate(character_id, [deaths, gain_xp, vehicle_destroys])

      %Session{
        session
        | character_id: character_id,
          faction_id: char.faction_id,
          name: char.name_first,
          outfit: char.outfit,
          battle_rank_ups: br_ups,
          deaths: deaths,
          gain_experiences: gain_xp,
          player_facility_captures: facility_caps,
          player_facility_defends: facility_defs,
          vehicle_destroys: vehicle_destroys,
          login: login,
          logout: logout
      }
    end)
    |> Enum.to_list()
  end

  def get(character_name, %Events.PlayerLogin{timestamp: timestamp}) do
    get(character_name, timestamp)
  end

  def get(character_name, login_timestamp) do
    {:ok, %Character{character_id: character_id} = char} = Characters.get_by_name(character_name)

    character_id = SacaStats.Utils.maybe_to_int(character_id, 0)

    logout_timestamp = get_logout_timestamp(character_id, login_timestamp)

    where_clause =
      dynamic(
        [e],
        field(e, :character_id) == ^character_id and
          field(e, :timestamp) >= ^login_timestamp
      )

    where_clause = build_where_clause(where_clause, logout_timestamp)

    attack_where_clause =
      dynamic(
        [e],
        (field(e, :character_id) == ^character_id or
           field(e, :attacker_character_id) == ^character_id) and
          field(e, :timestamp) >= ^login_timestamp
      )

    attack_where_clause = build_where_clause(attack_where_clause, logout_timestamp)

    ge_where_clause =
      character_id
      |> ge_where_clause(login_timestamp)
      |> build_where_clause(logout_timestamp)

    br_ups = Repo.all(gen_session_events_query(Events.BattleRankUp, where_clause))
    deaths = Repo.all(gen_session_events_query(Events.Death, attack_where_clause))
    gain_xp = Repo.all(gen_session_events_query(Events.GainExperience, ge_where_clause))
    facility_caps = Repo.all(gen_session_events_query(Events.PlayerFacilityCapture, where_clause))
    facility_defs = Repo.all(gen_session_events_query(Events.PlayerFacilityDefend, where_clause))

    vehicle_destroys =
      Repo.all(gen_session_events_query(Events.VehicleDestroy, attack_where_clause))

    %Session{} = session = aggregate(character_id, [deaths, gain_xp, vehicle_destroys])

    login =
      Repo.one!(
        from event in Events.PlayerLogin,
          where: event.timestamp == ^login_timestamp and event.character_id == ^character_id,
          limit: 1
      )

    logout =
      if logout_timestamp == :current_session do
        %{timestamp: :current_session, character_id: character_id}
      else
        Repo.one!(
          from event in Events.PlayerLogout,
            where: event.timestamp == ^logout_timestamp and event.character_id == ^character_id,
            limit: 1
        )
      end

    %Session{
      session
      | character_id: character_id,
        faction_id: char.faction_id,
        name: char.name_first,
        outfit: char.outfit,
        battle_rank_ups: br_ups,
        deaths: deaths,
        gain_experiences: gain_xp,
        player_facility_captures: facility_caps,
        player_facility_defends: facility_defs,
        vehicle_destroys: vehicle_destroys,
        login: login,
        logout: logout
    }
  end

  defp ge_where_clause(character_id, login_timestamp) do
    revive_xp_ids = SacaStats.revive_xp_ids()

    dynamic(
      [e],
      (field(e, :character_id) == ^character_id and
         field(e, :timestamp) >= ^login_timestamp) or
        (field(e, :other_id) == ^character_id and
           field(e, :experience_id) in ^revive_xp_ids and
           field(e, :timestamp) >= ^login_timestamp)
    )
  end

  defp get_logout_timestamp(character_id, login_timestamp) do
    query =
      from event in Events.PlayerLogout,
        select: min(event.timestamp),
        where: event.character_id == ^character_id and event.timestamp > ^login_timestamp

    case Repo.one(query) do
      nil -> :current_session
      logout_timestamp -> logout_timestamp
    end
  end

  @doc """
  ❗**Expensive Operation**❗

  Takes a session, sorts its events and combines them in one list, and gathers all the `%Character{}`s associated
  with those events. Returns both the events and the characters mapped by their IDs. May return `:error` if the
  character fetches fail.
  """
  @spec get_events_and_character_map(Session.t()) :: {:ok, list(), map()} | :error
  def get_events_and_character_map(session) do
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

    case Characters.get_many_by_id(all_character_ids, _shallow_copy = true) do
      {:ok, character_map} ->
        {:ok, events, character_map}

      :error ->
        Logger.error("Could not fetch many character IDs: #{inspect(all_character_ids)}")

        :error
    end
  end

  defp gen_session_events_query(event_module, conditional) do
    from event in event_module, where: ^conditional
  end

  def aggregate(%Session{character_id: character_id} = session, event_lists) do
    Enum.reduce(event_lists, session, fn event_list, aggregate_session ->
      Enum.reduce(event_list, aggregate_session, &event_reducer(character_id, &1, &2))
    end)
  end

  def aggregate(character_id, event_lists) do
    aggregate(%Session{character_id: character_id}, event_lists)
  end

  defp event_reducer(character_id, %Events.Death{} = death, %Session{} = session) do
    attackers_weapon = SacaStats.weapons()[death.attacker_weapon_id]

    kill_count_add = bool_to_int(death.attacker_character_id == character_id)

    kill_hs_count_add =
      bool_to_int(death.attacker_character_id == character_id and death.is_headshot)

    kill_ivi_count_add =
      bool_to_int(
        death.attacker_character_id == character_id and
          attackers_weapon["sanction"] == "infantry"
      )

    kill_hs_ivi_count_add =
      bool_to_int(
        death.attacker_character_id == character_id and
          attackers_weapon["sanction"] == "infantry" and
          death.is_headshot
      )

    death_count_add = bool_to_int(death.character_id == character_id)

    death_ivi_count_add =
      bool_to_int(
        death.character_id == character_id and attackers_weapon["sanction"] == "infantry"
      )

    session
    |> Map.update(:kill_count, kill_count_add, &(&1 + kill_count_add))
    |> Map.update(:kill_hs_count, kill_hs_count_add, &(&1 + kill_hs_count_add))
    |> Map.update(:kill_ivi_count, kill_ivi_count_add, &(&1 + kill_ivi_count_add))
    |> Map.update(:kill_hs_ivi_count, kill_hs_ivi_count_add, &(&1 + kill_hs_ivi_count_add))
    |> Map.update(:death_count, death_count_add, &(&1 + death_count_add))
    |> Map.update(:death_ivi_count, death_ivi_count_add, &(&1 + death_ivi_count_add))
  end

  defp event_reducer(_character_id, %Events.GainExperience{} = xp, %Session{} = session) do
    revive_count_add =
      bool_to_int(
        xp.other_id == session.character_id && xp.experience_id in SacaStats.revive_xp_ids()
      )

    session
    |> Map.update(:xp_earned, xp.amount, &(&1 + xp.amount))
    |> Map.update(:revive_count, revive_count_add, &(&1 + revive_count_add))
  end

  defp event_reducer(character_id, %Events.VehicleDestroy{} = vehicle, %Session{} = session) do
    character_vehicle = SacaStats.vehicles()[vehicle.vehicle_id]

    vehicle_kill_count_add = bool_to_int(vehicle.attacker_character_id == character_id)
    vehicle_death_count_add = bool_to_int(vehicle.character_id == character_id)

    nanites_destroyed_add =
      (vehicle.attacker_character_id == character_id && character_vehicle["cost"]) || 0

    nanites_lost_add = (vehicle.character_id == character_id && character_vehicle["cost"]) || 0

    session
    |> Map.update(:vehicle_kill_count, vehicle_kill_count_add, &(&1 + vehicle_kill_count_add))
    |> Map.update(:vehicle_death_count, vehicle_death_count_add, &(&1 + vehicle_death_count_add))
    |> Map.update(:nanites_destroyed, nanites_destroyed_add, &(&1 + nanites_destroyed_add))
    |> Map.update(:nanites_lost, nanites_lost_add, &(&1 + nanites_lost_add))
  end

  defp event_reducer(_character_id, %PlayerFacilityCapture{} = cap, session) do
    Map.update(session, :player_facility_captures, [cap], &[cap | &1])
  end

  defp event_reducer(_character_id, %PlayerFacilityDefend{} = def, session) do
    Map.update(session, :player_facility_defends, [def], &[def | &1])
  end

  defp event_reducer(_character_id, %BattleRankUp{} = br_up, session) do
    Map.update(session, :battle_rank_ups, [br_up], &[br_up | &1])
  end

  defp event_reducer(_character_id, event, session) do
    Logger.debug(
      "event_reducer received event that doesn't affect aggregate stats: #{inspect(event)}"
    )

    session
  end

  defp build_where_clause(clause, logout_timestamp) do
    case logout_timestamp do
      :current_session ->
        clause

      logout_timestamp ->
        dynamic([e], field(e, :timestamp) <= ^logout_timestamp and ^clause)
    end
  end
end
