defmodule SacaStats.Repo.Migrations.AddInitialEvents do
  use Ecto.Migration

  def change do
    create table(:deaths) do
      add :description, :string
      add :attacker_character_id, :bigint
      add :attacker_fire_mode_id, :integer
      add :attacker_loadout_id, :integer
      add :attacker_vehicle_id, :integer
      add :attacker_weapon_id, :integer
      add :character_id, :bigint
      add :character_loadout_id, :integer
      add :is_headshot, :boolean
      add :timestamp, :integer
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

    create table(:vehicle_destroys) do
      add :attacker_character_id, :bigint
      add :attacker_loadout_id, :integer
      add :attacker_vehicle_id, :integer
      add :attacker_weapon_id, :integer
      add :character_id, :bigint
      add :facility_id, :integer
      add :faction_id, :integer
      add :timestamp, :integer
      add :vehicle_id, :integer
      add :world_id, :integer
      add :zone_id, :integer
    end

    create table(:player_logouts) do
      add :character_id, :bigint
      add :timestamp, :integer
      add :world_id, :integer
    end

    create table(:player_logins) do
      add :character_id, :bigint
      add :timestamp, :integer
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

    create table(:player_facility_defends) do
      add :character_id, :bigint
      add :facility_id, :integer
      add :outfit_id, :bigint
      add :timestamp, :integer
      add :world_id, :integer
      add :zone_id, :integer
    end

    create table(:player_facility_captures) do
      add :character_id, :bigint
      add :facility_id, :integer
      add :outfit_id, :bigint
      add :timestamp, :integer
      add :world_id, :integer
      add :zone_id, :integer
    end

    create table(:battle_rank_ups) do
      add :battle_rank, :integer
      add :character_id, :bigint
      add :timestamp, :integer
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
