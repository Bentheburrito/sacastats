defmodule SacaStats.Events.Death do
  @moduledoc """
  Ecto schema for Death events.
  """
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :id, autogenerate: true}

  schema "deaths" do
    field :attacker_character_id, :integer
    field :attacker_fire_mode_id, :integer
    field :attacker_loadout_id, :integer
    field :attacker_vehicle_id, :integer
    field :attacker_weapon_id, :integer
    field :character_id, :integer
    field :character_loadout_id, :integer
    field :is_headshot, :boolean
    field :timestamp, :integer
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
  end
end
