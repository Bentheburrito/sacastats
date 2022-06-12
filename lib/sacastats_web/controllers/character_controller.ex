require Logger

defmodule SacaStatsWeb.CharacterController do
  use SacaStatsWeb, :controller

  import SacaStats.Utils

  alias SacaStats.{CensusCache, Session}

  @excluded_weapon_categories [
    "Infantry Abilities",
    "Vehicle Abilities",
    "ANT Harvesting Tool"
  ]

  def general(conn, %{"character_name" => _name}) do
    redirect(conn, to: conn.request_path <> "/general")
  end

  def search(conn, _params) do
    render(conn, "lookup.html")
  end

  def character(conn, %{"character_name" => name, "stat_type" => "sessions"}) do
    {:ok, info} = CensusCache.get(SacaStats.CharacterCache, name)
    sessions = Session.get_summary(name)

    {:ok, status} =
      CensusCache.get(SacaStats.OnlineStatusCache, String.to_integer(info["character_id"]))

    assigns = [
      character_info: info,
      online_status: status,
      stat_page: "sessions.html",
      sessions: sessions
    ]

    render(conn, "template.html", assigns)
  end

  def character(%Plug.Conn{} = conn, %{"character_name" => name, "stat_type" => stat_type}) do
    with {:ok, info} <- CensusCache.get(SacaStats.CharacterCache, name),
         {:ok, status} <- CensusCache.get(SacaStats.OnlineStatusCache, info["character_id"]) do
      assigns = build_assigns(info, status, stat_type)
      render(conn, "template.html", assigns)
    else
      {:error, :not_found} ->
        conn
        |> put_flash(
          :error,
          "Could not find a character called '#{name}'. Make sure it's spelled correctly, then try again"
        )
        |> redirect(to: Routes.character_path(conn, :search))

      {:error, e} ->
        Logger.error("Error fetching character: #{inspect(e)}")

        conn
        |> put_flash(
          :error,
          "We are unable to get that character right now. Please try again soon."
        )
        |> redirect(to: Routes.character_path(conn, :search))
    end
  end

  defp build_assigns(info, status, "weapons") do
    weapon_general_stats = Enum.reduce(info["stats"]["weapon_stat"], %{}, &put_weapon_stat/2)

    weapon_faction_stats =
      Enum.reduce(info["stats"]["weapon_stat_by_faction"], %{}, &put_weapon_stat/2)

    complete_weapon_stats =
      Map.merge(weapon_general_stats, weapon_faction_stats, fn _item_id, map1, map2 ->
        Map.merge(map1, map2)
      end)

    complete_weapons =
      for {weapon_id, weapon} <- SacaStats.weapons(),
          weapon_id = Integer.to_string(weapon_id),
          is_map_key(complete_weapon_stats, weapon_id),
          is_map_key(complete_weapon_stats[weapon_id], "weapon_play_time") or
            is_map_key(complete_weapon_stats[weapon_id], "weapon_killed_by"),
          weapon["category"] not in @excluded_weapon_categories,
          into: %{} do
        weapon_stats = Map.fetch!(complete_weapon_stats, weapon_id)
        {weapon_id, Map.merge(weapon, weapon_stats)}
      end

    type_set = get_sorted_set_of_items("category", complete_weapons)
    category_set = get_sorted_set_of_items("sanction", complete_weapons)

    [
      character_info: info,
      online_status: status,
      stat_page: "weapons.html",
      weapons: complete_weapons,
      types: type_set,
      categories: category_set
    ]
  end

  defp build_assigns(info, status, "general") do
    faction = SacaStats.Utils.maybe_to_int(info["faction_id"])
    head = SacaStats.Utils.maybe_to_int(info["head_id"])

    ethnicity = get_character_ethnicity(faction, head)
    sex = get_character_sex(faction, head)

    character_characteristics = %{
      "ethnicity" => ethnicity,
      "sex" => sex,
    }

    [
      character_info: info,
      online_status: status,
      stat_page: "general.html",
      character_characteristics: character_characteristics
    ]
  end

  defp build_assigns(info, status, stat_type) do
    [
      character_info: info,
      online_status: status,
      stat_page: stat_type <> ".html"
    ]
  end

  def session(conn, %{"character_name" => name, "login_timestamp" => login_timestamp}) do
    session = Session.get(name, login_timestamp)
    {:ok, status} = CensusCache.get(SacaStats.OnlineStatusCache, session.character_id)

    assigns = [
      character_info: %{
        "character_id" => session.character_id,
        "name" => %{"first" => session.name}
      },
      online_status: status,
      stat_page: "session.html",
      session: session
    ]

    render(conn, "template.html", assigns)
  end

  defp put_weapon_stat(weapon_stat, acc) do
    Map.update(
      acc,
      weapon_stat["item_id"],
      %{weapon_stat["stat_name"] => get_stat_values(weapon_stat)},
      &Map.put(&1, weapon_stat["stat_name"], get_stat_values(weapon_stat))
    )
  end

  defp get_stat_values(%{"value" => value}), do: value

  defp get_stat_values(%{"value_nc" => _} = w_stat),
    do: Map.take(w_stat, ["value_nc", "value_vs", "value_tr"])

  def get_aurax_percent(infantry_kills, vehicle_kills) do
    (100 * (infantry_kills + vehicle_kills) / 1160)
    |> Float.round(2)
    # max out at 100%
    |> min(100)
  end

  def get_medal_code(infantry_kills, vehicle_kills) when infantry_kills + vehicle_kills >= 1160,
    do: 3068

  def get_medal_code(infantry_kills, vehicle_kills) when infantry_kills + vehicle_kills >= 160,
    do: 3075

  def get_medal_code(infantry_kills, vehicle_kills) when infantry_kills + vehicle_kills >= 60,
    do: 3079

  def get_medal_code(infantry_kills, vehicle_kills) when infantry_kills + vehicle_kills >= 10,
    do: 3072

  def get_medal_code(_infantry_kills, _vehicle_kills), do: -1

  def get_faction_alias(4), do: "NSO"
  def get_faction_alias(3), do: "TR"
  def get_faction_alias(2), do: "NC"
  def get_faction_alias(1), do: "VS"
  def get_faction_alias(faction_id) when faction_id in [nil, 0], do: "NS"

  def get_total_values(nil, _faction_id), do: 0

  def get_total_values(%{"value_nc" => nc, "value_vs" => vs, "value_tr" => tr}, faction_id) do
    case maybe_to_int(faction_id) do
      0 -> maybe_to_int(nc) + maybe_to_int(vs) + maybe_to_int(tr)
      1 -> maybe_to_int(nc) + maybe_to_int(tr)
      2 -> maybe_to_int(vs) + maybe_to_int(tr)
      3 -> maybe_to_int(nc) + maybe_to_int(vs)
      4 -> maybe_to_int(nc) + maybe_to_int(vs) + maybe_to_int(tr)
    end
  end

  def get_cert_count(nil), do: 0

  def get_cert_count(score) do
    score
    |> SacaStats.Utils.maybe_to_int()
    |> div(250)
  end

  def get_percent_ratio(value, total_value) when total_value <= 0 or is_nil(total_value),
    do: value

  def get_percent_ratio(value, total_value) do
    value = maybe_to_int(value)
    total = maybe_to_int(total_value)

    Float.round(100 * (value / total), 2)
  end

  def get_sorted_set_of_items(set_value, map) do
    MapSet.new(
      for {_id, item} <- map do
        item[set_value]
      end
    )
    |> Enum.sort()
  end

  def get_kills_to_next_medal(total_kills) when total_kills >= 1160,
    do: "N/A"

  def get_kills_to_next_medal(total_kills) when total_kills >= 160,
    do: 1160 - total_kills

  def get_kills_to_next_medal(total_kills) when total_kills >= 60,
    do: 160 - total_kills

  def get_kills_to_next_medal(total_kills) when total_kills >= 10,
    do: 60 - total_kills

  def get_kills_to_next_medal(total_kills),
    do: 10 - total_kills

  def get_character_sex(faction_id, _head_id) when faction_id in [0, 4]
    do: "robot"

  def get_character_sex(_faction_id, head_id) when head_id <= 4,
    do: "male"

  def get_character_sex(_faction_id, head_id) when head_id > 4,
    do: "female"

  def get_character_ethnicity(faction_id, _head_id) when faction_id == 0 or faction_id == 4,
    do: "robot"

  def get_character_ethnicity(_faction_id, head_id) when head_id == 1 or head_id == 5,
    do: "caucasian"

  def get_character_ethnicity(_faction_id, head_id) when head_id == 2 or head_id == 6,
    do: "african"

  def get_character_ethnicity(_faction_id, head_id) when head_id == 3 or head_id == 7,
    do: "asian"

  def get_character_ethnicity(_faction_id, head_id) when head_id == 4 or head_id == 8,
    do: "hispanic"
end
