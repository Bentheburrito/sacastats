defmodule SacaStats.Characters do
  @moduledoc """
  Context module for character and character stat related functions and schemas
  """

  import SacaStats.Utils

  def get_sex(faction_id, _head_id) when faction_id in [0, 4], do: "robot"
  def get_sex(_faction_id, head_id) when head_id <= 4, do: "male"
  def get_sex(_faction_id, head_id) when head_id > 4, do: "female"

  def get_ethnicity(faction_id, _head_id) when faction_id in [0, 4], do: "robot"
  def get_ethnicity(_faction_id, head_id) when head_id in [1, 5], do: "caucasian"
  def get_ethnicity(_faction_id, head_id) when head_id in [2, 6], do: "african"
  def get_ethnicity(_faction_id, head_id) when head_id in [3, 7], do: "asian"
  def get_ethnicity(_faction_id, head_id) when head_id in [4, 8], do: "hispanic"

  def get_stat_by_name(nil, _name), do: 0

  def get_stat_by_name(stats, name) do
    stats
    |> Enum.find(&(&1["stat_name"] == name))
    |> Map.get("all_time")
    |> maybe_to_int(0)
  end
end
