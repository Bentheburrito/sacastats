defmodule SacaStats.Census.Character.WeaponStatByFaction do
  use Ecto.Schema
  import Ecto.Changeset
  @primary_key false

  embedded_schema do
    field :stat_name, :string
    field :item_id, :integer
    field :vehicle_id, :integer
    field :value_vs, :integer
    field :value_nc, :integer
    field :value_tr, :integer
    field :last_save, :integer
    # belongs_to :character, SacaStats.Census.Character, foreign_key: :character_id
  end

  def changeset_many(weapon_stat_by_faction, census_res_list) do
    for census_res <- census_res_list do
      changeset(weapon_stat_by_faction, census_res)
    end
  end

  def changeset(weapon_stat_by_faction, census_res \\ %{}) do
    weapon_stat_by_faction
    |> cast(census_res, [
      :stat_name,
      :item_id,
      :vehicle_id,
      :value_vs,
      :value_nc,
      :value_tr,
      :last_save
    ])
    |> validate_required([
      :stat_name,
      :item_id,
      :vehicle_id,
      :value_vs,
      :value_nc,
      :value_tr,
      :last_save
    ])
  end
end
