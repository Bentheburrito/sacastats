defmodule SacaStats.Census.Character do
  @moduledoc """
  Ecto schema and API for getting characters from the /character collection, joining their stats.
  """

  alias SacaStats.Census.Character.{
    Outfit,
    Stat,
    StatByFaction,
    StatHistory,
    WeaponStat,
    WeaponStatByFaction
  }

  require Logger

  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :character_id, :integer, primary_key: true
    field :name_first_lower, :string
    field :name_first, :string
    field :faction_id, :integer
    field :head_id, :integer
    field :title_id, :integer
    field :profile_id, :integer
    field :profile_type_description, :string
    field :prestige_level, :integer
    field :creation, :integer
    field :last_save, :integer
    field :last_login, :integer
    field :login_count, :integer
    field :minutes_played, :integer
    field :earned_points, :integer
    field :gifted_points, :integer
    field :available_points, :integer
    field :percent_to_next_point, :float
    field :battle_rank, :integer
    field :percent_to_next_br, :float
    embeds_many :stat_history, StatHistory
    embeds_many :stat, Stat
    embeds_many :stat_by_faction, StatByFaction
    embeds_many :weapon_stat, WeaponStat
    embeds_many :weapon_stat_by_faction, WeaponStatByFaction
    embeds_one :outfit, Outfit
  end

  @shallow_fields [
    :character_id,
    :name_first_lower,
    :name_first,
    :faction_id,
    :head_id,
    :title_id,
    :profile_id,
    :battle_rank,
    :percent_to_next_br,
    :prestige_level
  ]

  @fields @shallow_fields ++
            [
              :profile_type_description,
              :creation,
              :last_save,
              :last_login,
              :login_count,
              :minutes_played,
              :earned_points,
              :gifted_points,
              :available_points,
              :percent_to_next_point
            ]

  def changeset(character, census_res \\ %{}) do
    params =
      census_res
      # flatten name object
      |> Map.put("name_first_lower", census_res["name"]["first_lower"])
      |> Map.put("name_first", census_res["name"]["first"])
      # flatten br object
      |> Map.put("battle_rank", census_res["battle_rank"]["value"])
      |> Map.put("percent_to_next_br", census_res["battle_rank"]["percent_to_next"])
      # flatten/rename percent to next cert
      |> Map.put("percent_to_next_point", census_res["certs"]["percent_to_next"])
      # flatten times and certs objects
      |> Map.merge(census_res["times"])
      |> Map.merge(census_res["certs"])
      # flatten profile description
      |> Map.put("profile_type_description", census_res["profile"]["profile_type_description"])
      # flatten/rename character stats objects
      |> Map.put("stat_history", census_res["stats"]["stat_history"] || %{})
      |> Map.put("stat", census_res["stats"]["stat"] || %{})
      |> Map.put("stat_by_faction", census_res["stats"]["stat_by_faction"] || %{})

    character
    |> cast(params, @fields)
    |> validate_required(@fields)
    |> cast_embed(:stat_history, with: &StatHistory.changeset/2)
    |> cast_embed(:stat, with: &Stat.changeset/2)
    |> cast_embed(:stat_by_faction, with: &StatByFaction.changeset/2)
    |> cast_embed(:weapon_stat, with: &WeaponStat.changeset/2)
    |> cast_embed(:weapon_stat_by_faction, with: &WeaponStatByFaction.changeset/2)
    |> cast_embed(:outfit, with: &Outfit.changeset/2)
  end

  def shallow_changeset(character, census_res \\ %{}) do
    params =
      census_res
      # flatten name object
      |> Map.put("name_first_lower", census_res["name"]["first_lower"])
      |> Map.put("name_first", census_res["name"]["first"])
      # flatten br object
      |> Map.put("battle_rank", census_res["battle_rank"]["value"])
      |> Map.put("percent_to_next_br", census_res["battle_rank"]["percent_to_next"])

    character
    |> cast(params, @shallow_fields)
    |> validate_required(@shallow_fields)
  end
end
