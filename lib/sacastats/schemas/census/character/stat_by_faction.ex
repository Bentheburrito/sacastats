defmodule SacaStats.Census.Character.StatByFaction do
  @moduledoc """
  Ecto embedded schema for a character's stats by faction
  """

  use Ecto.Schema
  import Ecto.Changeset
  @primary_key false

  embedded_schema do
    field :stat_name, :string
    field :value_forever_vs, :integer
    field :value_forever_nc, :integer
    field :value_forever_tr, :integer
    # belongs_to :character, SacaStats.Census.Character
  end

  def changeset_many(stat_by_faction, census_res_list) do
    for census_res <- census_res_list do
      changeset(stat_by_faction, census_res)
    end
  end

  def changeset(stat_by_faction, census_res \\ %{}) do
    stat_by_faction
    |> cast(census_res, [:stat_name, :value_forever_vs, :value_forever_nc, :value_forever_tr])
    |> validate_required([:stat_name, :value_forever_vs, :value_forever_nc, :value_forever_tr])
  end
end
