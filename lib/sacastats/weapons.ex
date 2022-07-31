defmodule SacaStats.Weapons do
  @moduledoc """
  Context module for weapons and weapon stat related functions and schemas
  """

  alias SacaStats.Conversions

  import SacaStats.Utils

  @excluded_weapon_categories [
    "Infantry Abilities",
    "Vehicle Abilities",
    "ANT Harvesting Tool"
  ]

  # stat_name => {max_so_far, weapon}
  @init_highest_rank_acc %{
    "weapon_play_time" => {0, :no_weapon},
    "weapon_kills" => {0, :no_weapon},
    "weapon_killed_by" => {0, :no_weapon},
    "weapon_headshots" => {0, :no_weapon},
    "accuracy" => {0, :no_weapon},
    "kpm" => {0, :no_weapon}
  }

  def get_sorted_set_of_items(set_value_name, map) do
    MapSet.new(map, fn {_id, item} ->
      item[set_value_name]
    end)
    |> Stream.into([])
    |> Enum.sort()
  end

  @doc """
  Parses the characters_weapon_stat and characters_weapon_stat_by_faction lists from a character response into a
  """
  def compile_stats(stats) do
    weapon_faction_stats = Enum.reduce(stats["weapons_by_faction"], %{}, &put_weapon_stat/2)
    compiled_stats = Enum.reduce(stats["weapons"], weapon_faction_stats, &put_weapon_stat/2)

    for {weapon_id, weapon} <- SacaStats.weapons(),
        weapon_has_been_used?(compiled_stats, weapon_id, weapon["category"]),
        into: %{} do
      weapon_stats = Map.fetch!(compiled_stats, weapon_id)
      {weapon_id, Map.merge(weapon, weapon_stats)}
    end
  end

  defp weapon_has_been_used?(compiled_stats, weapon_id, weapon_category) do
    is_map_key(compiled_stats, weapon_id) and
      (is_map_key(compiled_stats[weapon_id], "weapon_play_time") or
         is_map_key(compiled_stats[weapon_id], "weapon_killed_by")) and
      weapon_category not in @excluded_weapon_categories
  end

  def compile_best_stats(compiled_stats) do
    %{
      "weapon_play_time" => {play_time, weapon_most_play_time},
      "weapon_kills" => {kills, weapon_most_kills},
      "weapon_killed_by" => {killed_by, weapon_most_killed_by},
      "weapon_headshots" => {headshots, weapon_most_headshots},
      "accuracy" => {accuracy, weapon_best_accuracy},
      "kpm" => {kpm, weapon_most_kpm}
    } = highest_rank_per_stat(compiled_stats)

    %{
      "Most Kills" => map_best_stats(weapon_most_kills, "number", kills),
      "Most Killed By" => map_best_stats(weapon_most_killed_by, "number", killed_by),
      "Most Used" => map_best_stats(weapon_most_play_time, "seconds-to-readable", play_time),
      "Most Headshots" => map_best_stats(weapon_most_headshots, "number", headshots),
      "Best Accuracy" => map_best_stats(weapon_best_accuracy, "percentage", accuracy),
      "Best KPM (Kills Per Minute)" => map_best_stats(weapon_most_kpm, "", kpm)
    }
  end

  defp map_best_stats(:no_weapon, _type, _value), do: :no_weapon

  defp map_best_stats(weapon, type, value) do
    %{
      "name" => weapon["name"],
      "type" => type,
      "weapon_type" => weapon["category"],
      "image_path" => weapon["image_path"],
      "value" => value
    }
  end

  def medal_counts(compiled_stats) do
    Enum.reduce(compiled_stats, %{}, fn {_weapon_id, weapon}, acc ->
      medal_type =
        Conversions.medal_name_by_kill_count(
          get_total_values(weapon["weapon_kills"]) +
            get_total_values(weapon["weapon_vehicle_kills"])
        )

      if medal_type == "none" do
        acc
      else
        acc
        |> Map.update(medal_type, 1, &(&1 + 1))
        |> Map.update("total", 1, &(&1 + 1))
      end
    end)
  end

  defp highest_rank_per_stat(weapon_stat_map) do
    Enum.reduce(weapon_stat_map, @init_highest_rank_acc, fn {_weapon_id, weapon}, acc ->
      %{
        "weapon_play_time" => weapon_play_time,
        "weapon_kills" => weapon_kills,
        "weapon_killed_by" => weapon_killed_by,
        "weapon_headshots" => weapon_headshots,
        "accuracy" => weapon_accuracy,
        "kpm" => weapon_kpm
      } = acc

      # Almost everyone would have a knife as their top-played weapon if we included the category
      play_time =
        if weapon["category"] == "Knife",
          do: 0,
          else: get_total_values(weapon["weapon_play_time"])

      kills = get_total_values(weapon["weapon_kills"])
      killed_by = get_total_values(weapon["weapon_killed_by"])
      headshots = get_total_values(weapon["weapon_headshots"])
      kpm = safe_divide(kills, play_time / 60, 2)

      # AOE weapons tend to have high accuracy, so we filter them out
      accuracy =
        if weapon["category"] in ["Explosive", "Grenade"] do
          0
        else
          hit_count = get_total_values(weapon["weapon_hit_count"])
          fire_count = get_total_values(weapon["weapon_fire_count"])
          to_percent(hit_count, fire_count)
        end

      %{
        acc
        | "weapon_play_time" => max_stat({play_time, weapon}, weapon_play_time),
          "weapon_kills" => max_stat({kills, weapon}, weapon_kills),
          "weapon_killed_by" => max_stat({killed_by, weapon}, weapon_killed_by),
          "weapon_headshots" => max_stat({headshots, weapon}, weapon_headshots),
          "accuracy" => max_stat({accuracy, weapon}, weapon_accuracy),
          "kpm" => max_stat({kpm, weapon}, weapon_kpm)
      }
    end)
  end

  defp max_stat({first_count, _weapon1} = first, {second_count, _weapon2} = second) do
    if first_count > second_count do
      first
    else
      second
    end
  end

  defp put_weapon_stat(weapon_stat, acc) do
    Map.update(
      acc,
      SacaStats.Utils.maybe_to_int(weapon_stat["item_id"], 0),
      %{weapon_stat["stat_name"] => get_stat_values(weapon_stat)},
      &Map.put(&1, weapon_stat["stat_name"], get_stat_values(weapon_stat))
    )
  end

  defp get_stat_values(%{"value" => value}), do: maybe_to_int(value, 0)

  defp get_stat_values(w_stat),
    do:
      Map.take(w_stat, ["value_nc", "value_vs", "value_tr"])
      |> Map.new(fn {key, val} -> {key, maybe_to_int(val, 0)} end)

  def get_total_values(nil, _faction_id), do: 0

  def get_total_values(%{"value_nc" => nc, "value_vs" => vs, "value_tr" => tr}, faction_id) do
    case maybe_to_int(faction_id, 0) do
      0 -> maybe_to_int(nc, 0) + maybe_to_int(vs, 0) + maybe_to_int(tr, 0)
      1 -> maybe_to_int(nc, 0) + maybe_to_int(tr, 0)
      2 -> maybe_to_int(vs, 0) + maybe_to_int(tr, 0)
      3 -> maybe_to_int(nc, 0) + maybe_to_int(vs, 0)
      4 -> maybe_to_int(nc, 0) + maybe_to_int(vs, 0) + maybe_to_int(tr, 0)
    end
  end

  def get_total_values(nil), do: 0

  def get_total_values(%{"value_nc" => nc, "value_vs" => vs, "value_tr" => tr}) do
    maybe_to_int(nc, 0) + maybe_to_int(vs, 0) + maybe_to_int(tr, 0)
  end

  def get_total_values(value) when value == true or value == false,
    do: bool_to_int(value)

  def get_total_values(value), do: maybe_to_int(value, 0)
end
