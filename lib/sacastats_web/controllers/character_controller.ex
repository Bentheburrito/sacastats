require Logger

defmodule SacaStatsWeb.CharacterController do
  use SacaStatsWeb, :controller
  alias SacaStatsWeb.CharacterView
  import PS2.API.QueryBuilder
  alias PS2.API.{Query, Join}

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

    body = handle_query_return(conn, query, name)

    next_rank =
      body
      |> get_in(["battle_rank", "value"])
      |> String.to_integer()
      |> Kernel.+(1)

    status = if body["online_status"] |> String.to_integer() > 0, do: "online", else: "offline"

    body = body |> Map.put("weapons", SacaStats.weapons())

    dataJSON =
      body
      |> Jason.encode!()

    weapons =
      SacaStats.weapons()
      |> Jason.encode!()

    vehicles =
      SacaStats.vehicles()
      |> Jason.encode!()

    character = %{
      "stat_page" => "general.html",
      "response" => body,
      "next_rank" => next_rank,
      "status" => status,
      "dataJSON" => dataJSON,
      "weapons" => SacaStats.weapons(),
      "vehicles" => vehicles
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

    body = handle_query_return(conn, query, name)

    next_rank =
      body
      |> get_in(["battle_rank", "value"])
      |> String.to_integer()
      |> Kernel.+(1)

    status = if body["online_status"] |> String.to_integer() > 0, do: "online", else: "offline"

    body = body |> Map.put("weapons", SacaStats.weapons())

    dataJSON =
      body
      |> Jason.encode!()

    weapons =
      SacaStats.weapons()
      |> Jason.encode!()

    vehicles =
      SacaStats.vehicles()
      |> Jason.encode!()

    character = %{
      "stat_page" => "stats.html",
      "response" => body,
      "next_rank" => next_rank,
      "status" => status,
      "dataJSON" => dataJSON,
      "weapons" => SacaStats.weapons(),
      "vehicles" => vehicles
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

    body = handle_query_return(conn, query, name)

    next_rank =
      body
      |> get_in(["battle_rank", "value"])
      |> String.to_integer()
      |> Kernel.+(1)

    status = if body["online_status"] |> String.to_integer() > 0, do: "online", else: "offline"

    body = body |> Map.put("weapons", SacaStats.weapons())

    dataJSON =
      body
      |> Jason.encode!()

    weapons =
      SacaStats.weapons()
      |> Jason.encode!()

    vehicles =
      SacaStats.vehicles()
      |> Jason.encode!()

    character = %{
      "stat_page" => "directives.html",
      "response" => body,
      "next_rank" => next_rank,
      "status" => status,
      "dataJSON" => dataJSON,
      "weapons" => SacaStats.weapons(),
      "vehicles" => vehicles
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

    body = handle_query_return(conn, query, name)

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
          is_map_key(complete_weapon_stats[Integer.to_string(weapon_id)], "weapon_play_time") and
            is_map_key(complete_weapon_stats[Integer.to_string(weapon_id)], "weapon_kills"),
          weapon["category"] not in [
            "Infantry Abilities",
            "Vehicle Abilities",
            "ANT Harvesting Tool"
          ],
          into: %{} do
        weapon_stats = Map.fetch!(complete_weapon_stats, Integer.to_string(weapon_id))
        {weapon_id, Map.merge(weapon, weapon_stats)}
      end

    status = if body["online_status"] |> String.to_integer() > 0, do: "online", else: "offline"

    dataJSON =
      body
      |> Jason.encode!()

    character = %{
      "stat_page" => "weapons.html",
      "response" => body,
      "weapons" => complete_weapons,
      "status" => status,
      "dataJSON" => dataJSON
    }

    render(conn, "template.html", character: character)
  end

  def character_session(conn, %{"character_name" => name, "stat_type" => "session"}) do
    # case CAIData.API.get_session_by_name(name) do
    #   {:ok, session} ->
    #     character_stuff = %{"name" => name, "stat_page" => "session.html"}
    #     render(conn, "characterTemplate.html", character: character_stuff, session: session)

    #   :none ->
    #     conn
    #     |> put_flash(:error, "No session under a character with that name.")
    #     |> render("index.html")
    # end
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

  def handle_query_return(conn, query, name) do
    case PS2.API.query(query) do
      {:ok, %PS2.API.QueryResult{returned: 0}} ->
        conn
        |> put_flash(:error, "The character '" <> name <> "' doesn't appear to exist.")
        |> redirect(to: Routes.character_path(conn, :character_search))

      {:ok, %PS2.API.QueryResult{data: [body]}} ->
        body

      {:error, e} ->
        Logger.error("Error fetching character: #{inspect(e)}")
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
    if(infantry_kills + vehicle_kills >= 1160) do
      100
    else
      Decimal.round(
        Decimal.mult(
          Decimal.div(
            Decimal.add(Decimal.new(infantry_kills), Decimal.new(vehicle_kills)),
            Decimal.new(1160)
          ),
          Decimal.new(100)
        ),
        0
      )
    end
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

  def get_faction_alias(nil), do: "All"

  def get_faction_alias(faction_id) do
    case faction_id do
      0 -> "All"
      1 -> "VS"
      2 -> "NC"
      3 -> "TR"
      4 -> "NS"
    end
  end

  def get_total_values(nil), do: 0

  def get_total_values(%{"value_nc" => nc, "value_vs" => vs, "value_tr" => tr}) do
    get_string_value_as_integer(nc) + get_string_value_as_integer(vs) +
      get_string_value_as_integer(tr)
  end

  def get_string_value_as_integer(value) do
    if value != "", do: String.to_integer(value), else: 0
  end
end
