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
    field :login_timestamp, Events.PlayerLogin.t()
    field :logout_timestamp, Events.PlayerLogout.t()
  end

  def get_all(character_id) do
    character_info_task = Task.async(fn ->
      Query.new(collection: "single_character_by_id")
      |> term("character_id", character_id)
      |> show(["character_id", "name", "faction_id"])
      |> PS2.API.query_one(SacaStats.sid())
    end)

    all_br_ups = Repo.all(from event in Events.BattleRankUp, where: event.character_id == ^character_id)
    all_deaths = Repo.all(from event in Events.Death, where: event.character_id == ^character_id)
    all_gain_xp = Repo.all(from event in Events.GainExperience, where: event.character_id == ^character_id)
    all_facility_caps = Repo.all(from event in Events.PlayerFacilityCapture, where: event.character_id == ^character_id)
    all_facility_defs = Repo.all(from event in Events.PlayerFacilityDefend, where: event.character_id == ^character_id)
    all_vehicle_destroys = Repo.all(from event in Events.VehicleDestroy, where: event.character_id == ^character_id)

    logins = Repo.all(from login in Events.PlayerLogin, where: login.character_id == ^character_id)
    logouts = Repo.all(from logout in Events.PlayerLogout, where: logout.character_id == ^character_id)

    latest_login = List.first(logins)
    latest_logout = List.first(logouts)

    # If this character is currently online/has a session open, then their most recent login will intuitively be more
    # recent than their most recent logout.
    logouts =
      cond do
        is_nil(latest_login) or is_nil(latest_logout) ->
          logouts
        latest_login.timestamp > latest_logout.timestamp ->
          [%{timestamp: :current_session} | logouts]
        :else ->
          logouts
      end

    {:ok, %QueryResult{data: character_info}} = Task.await(character_info_task)

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
        faction_id: character_info["faction_id"],
        name: character_info["name"]["first_lower"],
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
        battle_rank_ups: length(br_ups),
        deaths: deaths,
        gain_experiences: gain_xp,
        player_facility_captures: facility_caps,
        player_facility_defends: facility_defs,
        vehicle_destroys: vehicle_destroys,
        login_timestamp: login,
        logout_timestamp: logout,
      }
    end)
    |> Enum.to_list()
  end

  defp aggregate(character_id, event_lists) do
    event_lists
    |> Stream.map(fn events -> Enum.reduce(events, %{}, &event_reducer(character_id, &1, &2)) end)
    |> Enum.reduce(&Map.merge/2)
  end

  defp event_reducer(character_id, %Events.Death{} = death, acc) do
    attackers_weapon = SacaStats.weapons()[String.to_integer(death.attacker_weapon_id)]

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
    character_vehicle = SacaStats.vehicles()[String.to_integer(vehicle.vehicle_id)]

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
