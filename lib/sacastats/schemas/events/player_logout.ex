defmodule SacaStats.Events.PlayerLogout do
  @moduledoc """
  Ecto schema for PlayerLogout events.
  """
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key false

  schema "player_logouts" do
    field :character_id, :integer, primary_key: true
    field :timestamp, :integer, primary_key: true
    field :world_id, :integer
  end

  def changeset(event, params \\ %{}) do
    field_list =
      :fields
      |> __MODULE__.__schema__()
      |> List.delete(:id)

    event
    |> cast(params, field_list)
    |> unique_constraint([:character_id, :timestamp], name: "player_logouts_pkey")
  end
end
