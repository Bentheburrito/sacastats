defmodule SacaStats.Repo.Migrations.AddInitialEvents do
  use Ecto.Migration

  def change do
    create table(:deaths, primary_key: false) do
      add :character_id, :bigint, primary_key: true
      add :timestamp, :integer, primary_key: true
      add :attacker_character_id, :bigint, primary_key: true
      add :attacker_fire_mode_id, :integer
      add :attacker_loadout_id, :integer
      add :attacker_vehicle_id, :integer
      add :attacker_weapon_id, :integer
      add :character_loadout_id, :integer
      add :is_headshot, :boolean
      add :world_id, :integer
      add :zone_id, :integer
    end

    create table(:gain_experiences) do
      add :amount, :integer
      add :character_id, :bigint
      add :experience_id, :integer
      add :loadout_id, :integer
      add :other_id, :bigint
      add :timestamp, :integer
      add :world_id, :integer
      add :zone_id, :integer
    end

    create table(:vehicle_destroys, primary_key: false) do
      add :character_id, :bigint, primary_key: true
      add :timestamp, :integer, primary_key: true
      add :attacker_character_id, :bigint, primary_key: true
      add :attacker_loadout_id, :integer
      add :attacker_vehicle_id, :integer
      add :attacker_weapon_id, :integer
      add :facility_id, :integer
      add :faction_id, :integer
      add :vehicle_id, :integer
      add :world_id, :integer
      add :zone_id, :integer
    end

    create table(:player_logouts, primary_key: false) do
      add :character_id, :bigint, primary_key: true
      add :timestamp, :integer, primary_key: true
      add :world_id, :integer
    end

    create table(:player_logins, primary_key: false) do
      add :character_id, :bigint, primary_key: true
      add :timestamp, :integer, primary_key: true
      add :world_id, :integer
    end

    create table(:continent_unlocks) do
      add :metagame_event_id, :integer
      add :nc_population, :integer
      add :previous_faction, :integer
      add :timestamp, :integer
      add :tr_population, :integer
      add :triggering_faction, :integer
      add :vs_population, :integer
      add :world_id, :integer
      add :zone_id, :integer
    end

    create table(:continent_locks) do
      add :metagame_event_id, :integer
      add :nc_population, :integer
      add :previous_faction, :integer
      add :timestamp, :integer
      add :tr_population, :integer
      add :triggering_faction, :integer
      add :vs_population, :integer
      add :world_id, :integer
      add :zone_id, :integer
    end

    create table(:player_facility_defends, primary_key: false) do
      add :character_id, :bigint, primary_key: true
      add :timestamp, :integer, primary_key: true
      add :facility_id, :integer
      add :outfit_id, :bigint
      add :world_id, :integer
      add :zone_id, :integer
    end

    create table(:player_facility_captures, primary_key: false) do
      add :character_id, :bigint, primary_key: true
      add :timestamp, :integer, primary_key: true
      add :facility_id, :integer
      add :outfit_id, :bigint
      add :world_id, :integer
      add :zone_id, :integer
    end

    create table(:battle_rank_ups, primary_key: false) do
      add :character_id, :bigint, primary_key: true
      add :timestamp, :integer, primary_key: true
      add :battle_rank, :integer, primary_key: true
      add :world_id, :integer
      add :zone_id, :integer
    end

    create table(:metagame_events) do
      add :experience_bonus, :float
      add :faction_nc, :float
      add :faction_tr, :float
      add :faction_vs, :float
      add :instance_id, :integer
      add :metagame_event_id, :integer
      add :metagame_event_state, :integer
      add :metagame_event_state_name, :string
      add :timestamp, :integer
      add :world_id, :integer
      add :zone_id, :integer
    end
  end
end
