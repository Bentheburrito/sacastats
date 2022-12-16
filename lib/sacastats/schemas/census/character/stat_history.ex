defmodule SacaStats.Census.Character.StatHistory do
  use Ecto.Schema
  import Ecto.Changeset
  @primary_key false

  embedded_schema do
    field :stat_name, :string
    field :all_time, :integer
    # belongs_to :character, SacaStats.Census.Character, foreign_key: :character_id
  end

  def changeset_many(stat_history, census_res_list) do
    for census_res <- census_res_list do
      changeset(stat_history, census_res)
    end
  end

  def changeset(stat_history, census_res \\ %{}) do
    stat_history
    |> cast(census_res, [:stat_name, :all_time])
    |> validate_required([:stat_name, :all_time])
  end
end
