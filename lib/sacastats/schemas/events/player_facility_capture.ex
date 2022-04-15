defmodule SacaStats.Events.PlayerFacilityCapture do
  @moduledoc """
  Ecto schema for PlayerFacilityCapture events.
  """
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :id, autogenerate: true}

  schema "player_facility_captures" do
    field :character_id, :integer
    field :facility_id, :integer
    field :outfit_id, :integer
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
