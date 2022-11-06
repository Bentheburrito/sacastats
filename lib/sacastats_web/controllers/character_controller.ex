require Logger

defmodule SacaStatsWeb.CharacterController do
  use SacaStatsWeb, :controller
  import Ecto.Query

  alias SacaStats.{Characters, Weapons}
  alias SacaStats.{CensusCache, Session}
  alias SacaStats.Character.Favorite
  alias SacaStats.Repo

  def base(conn, %{"character_name" => _name}) do
    redirect(conn, to: conn.request_path <> "/general")
  end

  def add_favorite(conn, %{"character_name" => name} = params) do
    %{
      "discord_id" => discord_id,
      "character_id" => character_id,
      "last_known_name" => last_known_name
    } = Map.get(params, "favorite")

    return_path = Regex.replace(~r{/[^/]+$}, conn.request_path, "")

    if discord_id not in [nil, ""] && is_favorite?(character_id, discord_id) do
      conn
      |> put_flash(:error, "#{name} has already been favorited.")
      |> redirect(to: return_path)
    else
      # Add to DB.
      changeset =
        Favorite.changeset(%Favorite{}, %{
          :discord_id => discord_id,
          :character_id => character_id,
          :last_known_name => last_known_name
        })

      Repo.insert(changeset)

      # redir to general stat page for now
      # character(conn, Map.put(params, "stat_type", "general"))

      redirect(conn, to: return_path)
    end
  end

  def remove_favorite(conn, %{"character_name" => name} = params) do
    %{
      "discord_id" => user_id,
      "character_id" => id,
      "last_known_name" => _last_known_name
    } = Map.get(params, "favorite")

    return_path = Regex.replace(~r{/[^/]+$}, conn.request_path, "")

    if user_id not in [nil, ""] && is_favorite?(id, user_id) do
      # Remove from DB.
      Repo.delete_all(
        from(f in Favorite, where: f.discord_id == ^user_id and f.character_id == ^id)
      )

      # redir to general stat page for now
      # character(conn, Map.put(params, "stat_type", "general"))

      redirect(conn, to: return_path)
    else
      conn
      |> put_flash(:error, "#{name} has already been unfavorited.")
      |> redirect(to: return_path)
    end
  end

  def character_post(conn, _params) do
    redirect(conn, to: conn.request_path)
  end

  def character_optional_post(conn, _params) do
    redirect(conn, to: conn.request_path)
  end

  def search(conn, _params) do
    render(conn, "lookup.html")
  end

  def character(%Plug.Conn{} = conn, %{"character_name" => name, "stat_type" => stat_type}) do
    with {:ok, info} <- CensusCache.get(SacaStats.CharacterCache, name),
         {:ok, status} <- CensusCache.get(SacaStats.OnlineStatusCache, info["character_id"]) do
      user_id = if is_nil(conn.assigns.user), do: nil, else: conn.assigns.user.id
      assigns = build_assigns(info, status, stat_type, user_id)
      render(conn, "template.html", assigns)
    else
      {:error, :not_found} ->
        conn
        |> put_flash(
          :error,
          "Could not find a character called '#{name}'. Make sure it's spelled correctly, then try again"
        )
        |> redirect(to: "/character")

      {:error, e} ->
        Logger.error("Error fetching character: #{inspect(e)}")

        conn
        |> put_flash(
          :error,
          "We are unable to get that character right now. Please try again soon."
        )
        |> redirect(to: "/character")
    end
  end

  defp build_assigns(info, status, "sessions", user_id) do
    sessions = Session.get_summary(info["name"]["first_lower"])

    [
      character_info: info,
      online_status: status,
      stat_page: "sessions.html",
      sessions: sessions,
      is_favorite: is_favorite?(info["character_id"], user_id),
      changeset: Favorite.changeset(%Favorite{})
    ]
  end

  defp build_assigns(info, status, "weapons", user_id) do
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
          categories: category_set,
          is_favorite: is_favorite?(info["character_id"], user_id),
          changeset: Favorite.changeset(%Favorite{})
        ]

      {:error, :not_found} ->
        [
          character_info: info,
          online_status: status,
          stat_page: "weapons_not_found.html",
          is_favorite: is_favorite?(info["character_id"], user_id),
          changeset: Favorite.changeset(%Favorite{})
        ]
    end
  end

  defp build_assigns(info, status, "general", user_id) do
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
      best_weapons: best_weapons,
      is_favorite: is_favorite?(info["character_id"], user_id),
      changeset: Favorite.changeset(%Favorite{})
    ]
  end

  defp build_assigns(info, status, stat_type, user_id) do
    [
      character_info: info,
      online_status: status,
      stat_page: stat_type <> ".html",
      is_favorite: is_favorite?(info["character_id"], user_id),
      changeset: Favorite.changeset(%Favorite{})
    ]
  end

  defp is_favorite?(id, user_id) do
    if is_nil(user_id) do
      false
    else
      case Ecto.Query.from(f in Favorite,
             select: f,
             where: f.discord_id == ^user_id and f.character_id == ^id
           )
           |> Repo.all() do
        [] ->
          false

        [_favorite_character] ->
          true
      end
    end
  end

  @spec session(Plug.Conn.t(), map) :: Plug.Conn.t()
  def session(conn, %{"character_name" => name, "login_timestamp" => login_timestamp}) do
    session = Session.get(name, login_timestamp)
    {:ok, status} = CensusCache.get(SacaStats.OnlineStatusCache, session.character_id)

    user_id =
      if conn.assigns.user do
        conn.assigns.user.id
      else
        0
      end

    assigns = [
      character_info: %{
        "character_id" => session.character_id,
        "name" => %{"first" => session.name},
        "faction_id" => session.faction_id,
        "outfit" => session.outfit
      },
      online_status: status,
      stat_page: "session.html",
      session: session,
      is_favorite: is_favorite?(session.character_id, user_id),
      changeset: Favorite.changeset(%Favorite{})
    ]

    render(conn, "template.html", assigns)
  end
end
