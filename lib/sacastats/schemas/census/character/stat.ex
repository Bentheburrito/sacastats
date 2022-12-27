defmodule SacaStats.Census.Character.Stat do
  @moduledoc """
  Ecto embedded schema for a character's general stats
  """

  use Ecto.Schema
  import Ecto.Changeset
  @primary_key false

  embedded_schema do
    field :stat_name, :string
    field :value_forever, :integer
    # belongs_to :character, SacaStats.Census.Character, foreign_key: :character_id
  end

  def changeset_many(stat, census_res_list) do
    for census_res <- census_res_list do
      changeset(stat, census_res)
    end
  end

  def changeset(stat, census_res \\ %{}) do
    stat
    |> cast(census_res, [:stat_name, :value_forever])
    |> validate_required([:stat_name, :value_forever])
  end
end
