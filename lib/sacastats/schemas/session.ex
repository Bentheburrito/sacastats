defmodule SacaStats.Session do
  @moduledoc """
  Struct representing a character session. The data is populated from raw events stored in the DB. Use the functions in
  this module to build session structs for given character IDs and timestamps.
  """

  alias SacaStats.{Events, Repo, Session}

  import Ecto.Query
  import PS2.API.QueryBuilder
  alias PS2.API.{QueryResult, Query}
  import SacaStats.Utils, only: [typedstruct: 1]

  typedstruct do
    field :character_id, integer(), required?: true
    field :faction_id, integer()
    field :name, String.t()
    # aggregate data
    field :kill_count, integer()
    field :kill_hs_count, integer()
    field :kill_hs_ivi_count, integer()
    field :kill_ivi_count, integer()
    field :death_ivi_count, integer()
    field :death_count, integer()
    field :vehicle_kill_count, integer()
    field :vehicle_death_count, integer()
    field :nanites_destroyed, integer()
    field :nanites_lost, integer()
    field :xp_earned, integer()
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

  @default_aggregation %{
    kill_count: 0,
    kill_hs_count: 0,
    kill_ivi_count: 0,
    kill_hs_ivi_count: 0,
    death_count: 0,
    death_ivi_count: 0,
    vehicle_kill_count: 0,
    vehicle_death_count: 0,
    nanites_destroyed: 0,
    nanites_lost: 0,
    xp_earned: 0,
  }

  @doc """
  Gets a summary of all a character's sessions. This function is similar to `get_all/1`, except it does not fetch events
  (besides PlayerLogins and PlayerLogouts), and does not calculate aggregations. Therefore, this function is useful
  for seeing session durations and start/end times at a glance, when specific session data is not needed yet.
  """
  def get_summary(character_id_or_name) do
    %{"character_id" => character_id} = character_info = get_character_info(character_id_or_name)
    character_id = SacaStats.Utils.maybe_to_int(character_id)

    logins = Repo.all(from login in Events.PlayerLogin, where: login.character_id == ^character_id, order_by: [desc: :timestamp])
    logouts = Repo.all(from logout in Events.PlayerLogout, where: logout.character_id == ^character_id, order_by: [desc: :timestamp])

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
        (not is_nil(latest_login) and is_nil(latest_logout)) or latest_login.timestamp > latest_logout.timestamp ->
          [%{timestamp: :current_session} | logouts]

        :else ->
          logouts
      end

    logins
    |> Stream.zip(logouts)
    |> Stream.map(fn {login, logout} ->
      %Session{
        character_id: character_id,
        faction_id: SacaStats.Utils.maybe_to_int(character_info["faction_id"]),
        name: character_info["name"]["first"],
        login: login,
        logout: logout,
      }
    end)
    |> Enum.to_list()
  end

  def get_all(character_id_or_name) do
    %{"character_id" => character_id} = character_info = get_character_info(character_id_or_name)
    character_id = SacaStats.Utils.maybe_to_int(character_id)

    where_clause = [character_id: character_id]
    attack_where_clause = dynamic([e],
      field(e, :character_id) == ^character_id or
      field(e, :attacker_character_id) == ^character_id
    )

    all_br_ups = Repo.all(gen_session_events_query(Events.BattleRankUp, where_clause))
    all_deaths = Repo.all(gen_session_events_query(Events.Death, attack_where_clause))
    all_gain_xp = Repo.all(gen_session_events_query(Events.GainExperience, where_clause))
    all_facility_caps = Repo.all(gen_session_events_query(Events.PlayerFacilityCapture, where_clause))
    all_facility_defs = Repo.all(gen_session_events_query(Events.PlayerFacilityDefend, where_clause))
    all_vehicle_destroys = Repo.all(gen_session_events_query(Events.VehicleDestroy, attack_where_clause))

    logins = Repo.all(from login in Events.PlayerLogin, where: login.character_id == ^character_id, order_by: [desc: :timestamp])
    logouts = Repo.all(from logout in Events.PlayerLogout, where: logout.character_id == ^character_id, order_by: [desc: :timestamp])

    latest_login = List.first(logins)
    latest_logout = List.first(logouts)

    # If this character is currently online/has a session open, then their most recent login will be more
    # recent than their most recent logout. So we should add a map with a timestamp field that tells us just that.
    logouts =
      cond do
        is_nil(latest_login) or is_nil(latest_logout) ->
          logouts
        latest_login.timestamp > latest_logout.timestamp ->
          [%{timestamp: :current_session} | logouts]
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

      aggregations = aggregate(character_id, [deaths, gain_xp, vehicle_destroys])

      %Session{
        character_id: character_id,
        faction_id: SacaStats.Utils.maybe_to_int(character_info["faction_id"]),
        name: character_info["name"]["first"],
        kill_count: aggregations.kill_count,
        kill_hs_count: aggregations.kill_hs_count,
        kill_ivi_count: aggregations.kill_ivi_count,
        kill_hs_ivi_count: aggregations.kill_hs_ivi_count,
        death_count: aggregations.death_count,
        death_ivi_count: aggregations.death_ivi_count,
        vehicle_kill_count: aggregations.vehicle_kill_count,
        vehicle_death_count: aggregations.vehicle_death_count,
        nanites_destroyed: aggregations.nanites_destroyed,
        nanites_lost: aggregations.nanites_lost,
        xp_earned: aggregations.xp_earned,
        battle_rank_ups: br_ups,
        deaths: deaths,
        gain_experiences: gain_xp,
        player_facility_captures: facility_caps,
        player_facility_defends: facility_defs,
        vehicle_destroys: vehicle_destroys,
        login: login,
        logout: logout,
      }
    end)
    |> Enum.to_list()
  end

  def get(character_id_or_name, %Events.PlayerLogin{timestamp: timestamp}) do
    get(character_id_or_name, timestamp)
  end

  def get(character_id_or_name, login_timestamp) do
    %{"character_id" => character_id} = character_info = get_character_info(character_id_or_name)
    character_id = SacaStats.Utils.maybe_to_int(character_id)

    logout_timestamp = get_logout_timestamp(character_id, login_timestamp)

    where_clause = dynamic([e],
      field(e, :character_id) == ^character_id and
      field(e, :timestamp) >= ^login_timestamp
    )

    where_clause =
      case logout_timestamp do
        :current_session ->
          where_clause
        logout_timestamp ->
          dynamic([e], field(e, :timestamp) <= ^logout_timestamp and ^where_clause)
      end

    attack_where_clause = dynamic([e],
      (field(e, :character_id) == ^character_id or
      field(e, :attacker_character_id) == ^character_id) and
      field(e, :timestamp) >= ^login_timestamp
    )

    attack_where_clause =
      case logout_timestamp do
        :current_session ->
          attack_where_clause
        logout_timestamp ->
          dynamic([e], field(e, :timestamp) <= ^logout_timestamp and ^attack_where_clause)
      end

    br_ups = Repo.all(gen_session_events_query(Events.BattleRankUp, where_clause))
    deaths = Repo.all(gen_session_events_query(Events.Death, attack_where_clause))
    gain_xp = Repo.all(gen_session_events_query(Events.GainExperience, where_clause))
    facility_caps = Repo.all(gen_session_events_query(Events.PlayerFacilityCapture, where_clause))
    facility_defs = Repo.all(gen_session_events_query(Events.PlayerFacilityDefend, where_clause))
    vehicle_destroys = Repo.all(gen_session_events_query(Events.VehicleDestroy, attack_where_clause))

    aggregations = aggregate(character_id, [deaths, gain_xp, vehicle_destroys])

    login = Repo.one!(from event in Events.PlayerLogin,
      where: event.timestamp == ^login_timestamp and event.character_id == ^character_id,
      limit: 1)
    logout =
      if logout_timestamp == :current_session do
        %{timestamp: :current_session}
      else
        Repo.one!(from event in Events.PlayerLogout,
          where: event.timestamp == ^logout_timestamp and event.character_id == ^character_id,
          limit: 1)
      end

    %Session{
      character_id: character_id,
      faction_id: SacaStats.Utils.maybe_to_int(character_info["faction_id"]),
      name: character_info["name"]["first"],
      kill_count: aggregations.kill_count,
      kill_hs_count: aggregations.kill_hs_count,
      kill_ivi_count: aggregations.kill_ivi_count,
      kill_hs_ivi_count: aggregations.kill_hs_ivi_count,
      death_count: aggregations.death_count,
      death_ivi_count: aggregations.death_ivi_count,
      vehicle_kill_count: aggregations.vehicle_kill_count,
      vehicle_death_count: aggregations.vehicle_death_count,
      nanites_destroyed: aggregations.nanites_destroyed,
      nanites_lost: aggregations.nanites_lost,
      xp_earned: aggregations.xp_earned,
      battle_rank_ups: br_ups,
      deaths: deaths,
      gain_experiences: gain_xp,
      player_facility_captures: facility_caps,
      player_facility_defends: facility_defs,
      vehicle_destroys: vehicle_destroys,
      login: login,
      logout: logout,
    }
  end

  defp get_character_info(character_id_or_name) do
    term =
      if is_binary(character_id_or_name) do
        "name.first_lower"
      else
        "character_id"
      end

    {:ok, %QueryResult{data: character_info}} =
      Query.new(collection: "character")
      |> term(term, String.downcase(character_id_or_name))
      |> show(["character_id", "name", "faction_id"])
      |> PS2.API.query_one(SacaStats.sid())

    character_info
  end

  defp get_logout_timestamp(character_id, login_timestamp) do
    query = from event in Events.PlayerLogout,
      select: min(event.timestamp),
      where: event.character_id == ^character_id and event.timestamp > ^login_timestamp

    case Repo.one(query) do
      nil -> :current_session
      logout_timestamp -> logout_timestamp
    end
  end

  defp gen_session_events_query(event_module, conditional) do
    from event in event_module, where: ^conditional
  end

  defp aggregate(character_id, event_lists) do
    # event_lists
    # |> Stream.map(fn events -> Enum.reduce(events, @default_aggregation, &event_reducer(character_id, &1, &2)) end)
    # |> Enum.reduce(&Map.merge/2)

    Enum.reduce(event_lists, @default_aggregation, fn event_list, aggregates ->
      Enum.reduce(event_list, aggregates, &event_reducer(character_id, &1, &2))
    end)
  end

  defp event_reducer(character_id, %Events.Death{} = death, acc) do
    attackers_weapon = SacaStats.weapons()[death.attacker_weapon_id]

    kill_count_add = death.attacker_character_id == character_id && 1 || 0
    kill_hs_count_add = death.attacker_character_id == character_id and death.is_headshot && 1 || 0
    kill_ivi_count_add = death.attacker_character_id == character_id and attackers_weapon["sanction"] == "infantry" && 1 || 0
    kill_hs_ivi_count_add = death.attacker_character_id == character_id and attackers_weapon["sanction"] == "infantry" and death.is_headshot && 1 || 0
    death_count_add = death.character_id == character_id && 1 || 0
    death_ivi_count_add = death.character_id == character_id and attackers_weapon["sanction"] == "infantry" && 1 || 0

    acc
    |> Map.update(:kill_count, kill_count_add, &(&1 + kill_count_add))
    |> Map.update(:kill_hs_count, kill_hs_count_add, &(&1 + kill_hs_count_add))
    |> Map.update(:kill_ivi_count, kill_ivi_count_add, &(&1 + kill_ivi_count_add))
    |> Map.update(:kill_hs_ivi_count, kill_hs_ivi_count_add, &(&1 + kill_hs_ivi_count_add))
    |> Map.update(:death_count, death_count_add, &(&1 + death_count_add))
    |> Map.update(:death_ivi_count, death_ivi_count_add, &(&1 + death_ivi_count_add))
  end

  defp event_reducer(_character_id, %Events.GainExperience{} = xp, acc) do
    Map.update(acc, :xp_earned, xp.amount, &(&1 + xp.amount))
  end

  defp event_reducer(character_id, %Events.VehicleDestroy{} = vehicle, acc) do
    character_vehicle = SacaStats.vehicles()[vehicle.vehicle_id]

    vehicle_kill_count_add = vehicle.attacker_character_id == character_id && 1 || 0
    vehicle_death_count_add = vehicle.character_id == character_id && 1 || 0
    nanites_destroyed_add = vehicle.attacker_character_id == character_id && character_vehicle["cost"] || 0
    nanites_lost_add = vehicle.character_id == character_id && character_vehicle["cost"] || 0

    acc
    |> Map.update(:vehicle_kill_count, vehicle_kill_count_add, &(&1 + vehicle_kill_count_add))
    |> Map.update(:vehicle_death_count, vehicle_death_count_add, &(&1 + vehicle_death_count_add))
    |> Map.update(:nanites_destroyed, nanites_destroyed_add, &(&1 + nanites_destroyed_add))
    |> Map.update(:nanites_lost, nanites_lost_add, &(&1 + nanites_lost_add))
  end
end
