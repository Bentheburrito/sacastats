defmodule SacaStats.Character.Favorite do
  @moduledoc """
  Ecto schema for a favorite characters choosen by discord.
  """

  use Ecto.Schema
  import Ecto.Changeset
  @primary_key {:id, :integer, []}

  schema "favorite_characters" do
    field :discord_id, :integer
    field :character_id, :integer
    field :last_known_name, :string
  end

  @required_fields [
    :discord_id,
    :character_id,
    :last_known_name
  ]

  def changeset(favorite_character, params \\ %{}) do
    favorite_character
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
  end
end
