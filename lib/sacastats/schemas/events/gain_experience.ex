defmodule SacaStats.Events.GainExperience do
  @moduledoc """
  Ecto schema for GainExperience events.
  """
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :id, autogenerate: true}

  schema "gain_experiences" do
    field :amount, :integer
    field :character_id, :integer
    field :experience_id, :integer
    field :loadout_id, :integer
    field :other_id, :integer
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
