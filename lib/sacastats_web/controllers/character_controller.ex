require Logger

defmodule SacaStatsWeb.CharacterController do
  use SacaStatsWeb, :controller

  alias SacaStats.{Characters, Weapons}
  alias SacaStats.{CensusCache, Session}

  def base(conn, %{"character_name" => _name}) do
    redirect(conn, to: conn.request_path <> "/general")
  end

  def search(conn, _params) do
    render(conn, "lookup.html")
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

  defp build_assigns(info, status, "sessions") do
    sessions = Session.get_summary(info["name"]["first_lower"])

    [
      character_info: info,
      online_status: status,
      stat_page: "sessions.html",
      sessions: sessions
    ]
  end

  defp build_assigns(info, status, "weapons") do
    case CensusCache.get(SacaStats.CharacterStatsCache, info["character_id"]) do
      {:ok, stats} ->
        complete_weapons = Weapons.compile_stats(stats["stats"])
        type_set = Weapons.get_sorted_set_of_items("category", complete_weapons)
        category_set = Weapons.get_sorted_set_of_items("sanction", complete_weapons)

        [
          character_info: info,
          online_status: status,
          stat_page: "weapons.html",
          weapons: complete_weapons,
          types: type_set,
          categories: category_set
        ]

      {:error, :not_found} ->
        [
          character_info: info,
          online_status: status,
          stat_page: "weapons_not_found.html"
        ]
    end
  end

  defp build_assigns(info, status, "general") do
    {info, stats, best_weapons} =
      case CensusCache.get(SacaStats.CharacterStatsCache, info["character_id"]) do
        {:ok, stats} ->
          compiled_stats = Weapons.compile_stats(stats["stats"])
          info = Map.put(info, "all_medal_counts", Weapons.medal_counts(compiled_stats))
          best_weapons = Weapons.compile_best_stats(compiled_stats)
          {info, stats, best_weapons}

        {:error, :not_found} ->
          {info, %{}, %{}}
      end

    faction = SacaStats.Utils.maybe_to_int(info["faction_id"], 0)
    head = SacaStats.Utils.maybe_to_int(info["head_id"], 0)

    ethnicity = Characters.get_ethnicity(faction, head)
    sex = Characters.get_sex(faction, head)

    character_characteristics = %{
      "ethnicity" => ethnicity,
      "sex" => sex
    }

    leader_id = get_in(info, ["outfit", "leader_character_id"])

    info =
      if is_nil(leader_id) do
        info
      else
        case CensusCache.get(SacaStats.CharacterCache, leader_id) do
          {:ok, character} ->
            Map.put(info, "outfit_leader_name", character["name"]["first_lower"])

          _ ->
            info
        end
      end

    [
      character_info: info,
      character_stats: stats,
      online_status: status,
      stat_page: "general.html",
      character_characteristics: character_characteristics,
      best_weapons: best_weapons
    ]
  end

  defp build_assigns(info, status, stat_type) do
    [
      character_info: info,
      online_status: status,
      stat_page: stat_type <> ".html"
    ]
  end

  @spec session(Plug.Conn.t(), map) :: Plug.Conn.t()
  def session(conn, %{"character_name" => name, "login_timestamp" => login_timestamp}) do
    session = Session.get(name, login_timestamp)
    {:ok, status} = CensusCache.get(SacaStats.OnlineStatusCache, session.character_id)

    assigns = [
      character_info: %{
        "character_id" => session.character_id,
        "name" => %{"first" => session.name},
        "faction_id" => session.faction_id,
        "outfit" => session.outfit
      },
      online_status: status,
      stat_page: "session.html",
      session: session
    ]

    render(conn, "template.html", assigns)
  end
end
