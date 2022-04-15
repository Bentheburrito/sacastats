defmodule SacaStats.Events.BattleRankUp do
  @moduledoc """
  Ecto schema for BattleRankUp events.
  """
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :id, autogenerate: true}

  schema "battle_rank_ups" do
    field :battle_rank, :integer
    field :character_id, :integer
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
