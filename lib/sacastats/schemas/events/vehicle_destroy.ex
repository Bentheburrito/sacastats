defmodule SacaStats.Events.VehicleDestroy do
  @moduledoc """
  Ecto schema for VehicleDestroy events.
  """
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key false

  schema "vehicle_destroys" do
    field :character_id, :integer, primary_key: true
    field :timestamp, :integer, primary_key: true
    field :attacker_character_id, :integer, primary_key: true
    field :attacker_loadout_id, :integer
    field :attacker_vehicle_id, :integer
    field :attacker_weapon_id, :integer
    field :facility_id, :integer
    field :faction_id, :integer
    field :vehicle_id, :integer
    field :world_id, :integer
    field :zone_id, :integer
  end

  def changeset(event, params \\ %{}) do
    field_list =
      :fields
      |> __MODULE__.__schema__()
      |> List.delete(:id)

    event
    |> cast(params, field_list)
    |> unique_constraint([:character_id, :timestamp, :attacker_character_id], name: "vehicle_destroys_pkey")
  end
end
