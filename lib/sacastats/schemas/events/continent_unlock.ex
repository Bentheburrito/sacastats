defmodule SacaStats.Events.ContinentUnlock do
  @moduledoc """
  Ecto schema for ContinentUnlock events.
  """
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :id, autogenerate: true}

  schema "continent_unlocks" do
    field :metagame_event_id, :integer
    field :nc_population, :integer
    field :previous_faction, :integer
    field :timestamp, :integer
    field :tr_population, :integer
    field :triggering_faction, :integer
    field :vs_population, :integer
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
