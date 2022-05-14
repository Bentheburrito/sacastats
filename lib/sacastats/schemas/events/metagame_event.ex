defmodule SacaStats.Events.MetagameEvent do
  @moduledoc """
  Ecto schema for MetagameEvent events.
  """
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :id, autogenerate: true}

  schema "metagame_events" do
    field :experience_bonus, :float
    field :faction_nc, :float
    field :faction_tr, :float
    field :faction_vs, :float
    field :instance_id, :integer
    field :metagame_event_id, :integer
    field :metagame_event_state, :integer
    field :metagame_event_state_name, :string
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
