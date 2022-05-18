require Logger

defmodule SacaStatsWeb.CharacterController do
  use SacaStatsWeb, :controller

  import PS2.API.QueryBuilder
  import SacaStats.Utils

  alias PS2.API.{Join, Query}
  alias SacaStats.Session
  alias SacaStatsWeb.CharacterController

  @excluded_weapon_categories [
    "Infantry Abilities",
    "Vehicle Abilities",
    "ANT Harvesting Tool"
  ]

  @query_gens %{
    "general" => &CharacterController.general_query/1,
    "stats" => &CharacterController.stats_query/1,
    "directives" => &CharacterController.stats_query/1,
    "weapons" => &CharacterController.weapons_query/1
  }

  def general(conn, %{"character_name" => _name}) do
    redirect(conn, to: conn.request_path <> "/general")
  end

  def search(conn, _params) do
    render(conn, "lookup.html")
  end

  def character(%Plug.Conn{} = conn, %{"character_name" => name, "stat_type" => stat_type}) do
    with {:ok, query_gen} <- Map.fetch(@query_gens, stat_type),
         {:ok, info} <- SacaStats.CensusCache.get(SacaStats.CharacterCache, name, query_gen.(name)),
         {:ok, status} <- SacaStats.CensusCache.get(SacaStats.OnlineStatusCache, name, online_status_query(info["character_id"])) do
      parse_and_render(conn, info, status, stat_type)
    else
      {:error, :not_found} ->
        conn
        |> put_flash(:error, "The character '#{name}' doesn't appear to exist.")
        |> redirect(to: Routes.character_path(conn, :search))

      {:error, e} ->
        Logger.error("Error fetching character: #{inspect(e)}")

        conn
        |> put_flash(:error, "We are unable to get that character right now. Please try again soon.")
        |> redirect(to: Routes.character_path(conn, :search))

      :error ->
        conn
        |> put_flash(:error, "'#{stat_type}' is an unknown page.")
        |> redirect(to: Routes.character_path(conn, :search))
    end
  end

  defp parse_and_render(conn, info, status, "weapons") do

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
        weapon_stats = Map.fetch!(complete_weapon_stats, Integer.to_string(weapon_id))
        {weapon_id, Map.merge(weapon, weapon_stats)}
      end

    type_set = get_sorted_set_of_items("category", complete_weapons)
    category_set = get_sorted_set_of_items("sanction", complete_weapons)

    assigns = [
      character_info: info,
      online_status: status,
      stat_page: "weapons.html",
      weapons: complete_weapons,
      types: type_set,
      categories: category_set
    ]

    render(conn, "template.html", assigns)
  end

  defp parse_and_render(conn, info, status, stat_type) do
    render(conn, "template.html", character_info: info, online_status: status, stat_page: stat_type <> ".html")
  end

  def character(conn, %{"character_name" => name, "stat_type" => "sessions"}) do
    sessions = SacaStats.Session.get_summary(name)
    latest_session = List.first(sessions)

    status =
      case latest_session do
        %Session{logout: %SacaStats.Events.PlayerLogout{timestamp: ts}}
        when ts == :current_session ->
          "online"

        _ ->
          "offline"
      end

    character = %{
      "stat_page" => "sessions.html",
      "response" => %{
        # nil for now until we can pull it from the cache, instead of hitting the Census again
        "character_id" => nil,
        "name" => %{"first" => name}
      },
      "status" => status
    }

    render(conn, "template.html", sessions: sessions, character: character)
  end

  def session(conn, %{"character_name" => name, "login_timestamp" => login_timestamp}) do
    session = SacaStats.Session.get(name, login_timestamp)

    {:ok, %PS2.API.QueryResult{data: status}} =
      Query.new(collection: "characters_online_status")
      |> term("character_id", session.character_id)
      |> lang("en")
      |> PS2.API.query_one(SacaStats.sid())

    character = %{
      "stat_page" => "session.html",
      "response" => %{
        "character_id" => session.character_id,
        "name" => %{"first" => session.name}
      },
      "status" => (String.to_integer(status["online_status"]) > 0 && "online") || "offline"
    }

    render(conn, "template.html", session: session, character: character)
  end

  def general_query(name) do
    {&PS2.API.query_one/2,
      [Query.new(collection: "character")
      |> term("name.first_lower", String.downcase(name))
      |> resolve([
        "outfit(alias,id,name)"
      ])
      |> lang("en"), SacaStats.sid()]}
  end

  def stats_query(name) do
    {&PS2.API.query_one/2,
      [Query.new(collection: "character")
      |> term("name.first_lower", String.downcase(name))
      |> resolve([
        "outfit(alias,id,name)"
      ])
      |> join(
        Join.new(collection: "item_profile")
        |> on("items.item_id")
        |> to("item_id")
        |> list(true)
        |> show("profile_id")
        |> inject_at("classes_list")
      )
      |> lang("en"), SacaStats.sid()]}
  end

  def weapons_query(name) do
    {&PS2.API.query_one/2,
      [Query.new(collection: "character")
      |> term("name.first_lower", String.downcase(name))
      |> resolve([
        "online_status",
        "outfit(alias,id,name)",
        "weapon_stat",
        "weapon_stat_by_faction"
      ])
      |> lang("en")], SacaStats.sid()}
  end

  def online_status_query(character_id) do
    {&PS2.API.query_one/2,
      [Query.new(collection: "characters_online_status")
      |> term("character_id", character_id), SacaStats.sid()]}
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

  def get_medal_code(infantry_kills, vehicle_kills) when infantry_kills + vehicle_kills >= 1160, do: 3068
  def get_medal_code(infantry_kills, vehicle_kills) when infantry_kills + vehicle_kills >= 160, do: 3075
  def get_medal_code(infantry_kills, vehicle_kills) when infantry_kills + vehicle_kills >= 60, do: 3079
  def get_medal_code(infantry_kills, vehicle_kills) when infantry_kills + vehicle_kills >= 10, do: 3072
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
    |> Integer.parse()
    |> elem(0)
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
end
