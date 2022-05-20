require Logger

defmodule SacaStatsWeb.CharacterController do
  use SacaStatsWeb, :controller

  import PS2.API.QueryBuilder
  import SacaStats.Utils

  alias PS2.API.{Join, Query}
  alias SacaStats.Session

  def character(conn, %{"character_name" => name, "stat_type" => "lookup"}) do
    redirect(conn, to: Routes.character_path(conn, :character, name, "general"))
  end

  def character(conn, %{"character_name" => name, "stat_type" => "general"}) do
    query =
      Query.new(collection: "character")
      |> term("name.first_lower", String.downcase(name))
      |> resolve([
        "online_status",
        "world",
        "outfit(alias,id,name)"
      ])
      |> lang("en")

    body = query_or_redirect(conn, query, name)

    next_rank =
      body
      |> get_in(["battle_rank", "value"])
      |> String.to_integer()
      |> Kernel.+(1)

    status = if body["online_status"] |> String.to_integer() > 0, do: "online", else: "offline"

    character = %{
      "stat_page" => "general.html",
      "response" => body,
      "next_rank" => next_rank,
      "status" => status
    }

    render(conn, "template.html", character: character)
  end

  def character(conn, %{"character_name" => name, "stat_type" => "stats"}) do
    query =
      Query.new(collection: "character")
      |> term("name.first_lower", String.downcase(name))
      |> resolve([
        "online_status",
        "world",
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
      |> lang("en")

    body = query_or_redirect(conn, query, name)

    next_rank =
      body
      |> get_in(["battle_rank", "value"])
      |> String.to_integer()
      |> Kernel.+(1)

    status = if body["online_status"] |> String.to_integer() > 0, do: "online", else: "offline"

    character = %{
      "stat_page" => "stats.html",
      "response" => body,
      "next_rank" => next_rank,
      "status" => status
    }

    render(conn, "template.html", character: character)
  end

  def character(conn, %{"character_name" => name, "stat_type" => "directives"}) do
    query =
      Query.new(collection: "character")
      |> term("name.first_lower", String.downcase(name))
      |> resolve([
        "online_status",
        "world",
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
      |> lang("en")

    body = query_or_redirect(conn, query, name)

    next_rank =
      body
      |> get_in(["battle_rank", "value"])
      |> String.to_integer()
      |> Kernel.+(1)

    status = if body["online_status"] |> String.to_integer() > 0, do: "online", else: "offline"

    character = %{
      "stat_page" => "directives.html",
      "response" => body,
      "next_rank" => next_rank,
      "status" => status
    }

    render(conn, "template.html", character: character)
  end

  def character(conn, %{"character_name" => name, "stat_type" => "weapons"}) do
    query =
      Query.new(collection: "character")
      |> term("name.first_lower", String.downcase(name))
      |> resolve([
        "online_status",
        "outfit(alias,id,name)",
        "weapon_stat",
        "weapon_stat_by_faction"
      ])
      |> lang("en")

    body = query_or_redirect(conn, query, name)

    weapon_general_stats = Enum.reduce(body["stats"]["weapon_stat"], %{}, &put_weapon_stat/2)

    weapon_faction_stats =
      Enum.reduce(body["stats"]["weapon_stat_by_faction"], %{}, &put_weapon_stat/2)

    complete_weapon_stats =
      Map.merge(weapon_general_stats, weapon_faction_stats, fn _item_id, map1, map2 ->
        Map.merge(map1, map2)
      end)

    complete_weapons =
      for {weapon_id, weapon} <- SacaStats.weapons(),
          is_map_key(complete_weapon_stats, Integer.to_string(weapon_id)),
          is_map_key(complete_weapon_stats[Integer.to_string(weapon_id)], "weapon_play_time") or
            is_map_key(complete_weapon_stats[Integer.to_string(weapon_id)], "weapon_killed_by"),
          weapon["category"] not in [
            "Infantry Abilities",
            "Vehicle Abilities",
            "ANT Harvesting Tool"
          ],
          into: %{} do
        weapon_stats = Map.fetch!(complete_weapon_stats, Integer.to_string(weapon_id))
        {weapon_id, Map.merge(weapon, weapon_stats)}
      end

    faction_set =
      for id <- get_sorted_set_of_items("faction_id", complete_weapons) do
        get_faction_alias(id)
      end
      |> MapSet.new()
      |> Enum.sort()

    type_set = get_sorted_set_of_items("category", complete_weapons)
    category_set = get_sorted_set_of_items("sanction", complete_weapons)

    status = if body["online_status"] |> String.to_integer() > 0, do: "online", else: "offline"

    character = %{
      "stat_page" => "weapons.html",
      "response" => body,
      "weapons" => complete_weapons,
      "status" => status,
      "factions" => faction_set,
      "types" => type_set,
      "categories" => category_set
    }

    render(conn, "template.html", character: character)
  end

  def character_sessions(conn, %{"character_name" => name}) do
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

  def character_session(conn, %{"character_name" => name, "login_timestamp" => login_timestamp}) do
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

  def character_general(conn, %{"character_name" => _name}) do
    redirect(conn, to: conn.request_path <> "/general")
  end

  def character_search(conn, _params) do
    render(conn, "lookup.html")
  end

  def character_find(conn, _params) do
    conn = parse(conn)
    name = conn.params["character"]

    redirect(conn, to: Routes.character_path(conn, :character, name, "general"))
  end

  def parse(conn, opts \\ []) do
    opts = Keyword.put_new(opts, :parsers, [Plug.Parsers.URLENCODED, Plug.Parsers.MULTIPART])
    Plug.Parsers.call(conn, Plug.Parsers.init(opts))
  end

  def query_or_redirect(conn, query, name) do
    case PS2.API.query(query, SacaStats.sid()) do
      {:ok, %PS2.API.QueryResult{returned: 0}} ->
        conn
        |> put_flash(:error, "The character '#{name}' doesn't appear to exist.")
        |> redirect(to: Routes.character_path(conn, :character_search))

      {:ok, %PS2.API.QueryResult{data: [body]}} ->
        body

      {:error, e} ->
        Logger.error("Error fetching character: #{inspect(e)}")

        conn
        |> put_flash(:error, "Couldn't get that character right now. Please try again soon.")
        |> redirect(to: Routes.character_path(conn, :character_search))
    end
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

  def get_medal_code(infantry_kills, vehicle_kills) do
    total_kills = infantry_kills + vehicle_kills

    cond do
      total_kills >= 1160 ->
        3068

      total_kills >= 160 ->
        3075

      total_kills >= 60 ->
        3079

      total_kills >= 10 ->
        3072

      true ->
        -1
    end
  end

  def get_faction_alias(faction_id) do
    case faction_id do
      nil -> "NS"
      0 -> "NS"
      1 -> "VS"
      2 -> "NC"
      3 -> "TR"
      4 -> "NSO"
    end
  end

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

  def get_kills_to_next_medals(total_kills) when total_kills >= 1160,
    do: "N/A"

  def get_kills_to_next_medals(total_kills) when total_kills >= 160,
    do: 1160 - total_kills

  def get_kills_to_next_medals(total_kills) when total_kills >= 60,
    do: 160 - total_kills

  def get_kills_to_next_medals(total_kills) when total_kills >= 10,
    do: 60 - total_kills

  def get_kills_to_next_medals(total_kills),
    do: 10 - total_kills
end
