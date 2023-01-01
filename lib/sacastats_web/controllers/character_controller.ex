require Logger

defmodule SacaStatsWeb.CharacterController do
  use SacaStatsWeb, :controller
  import Ecto.Query

  alias SacaStats.Census.{Character, OnlineStatus}
  alias SacaStats.Character.Favorite
  alias SacaStats.Characters
  alias SacaStats.Repo
  alias SacaStats.Session
  alias SacaStats.Weapons

  alias Phoenix.PubSub

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

      case Repo.insert(changeset) do
        {:ok, favorite} ->
          PubSub.broadcast(
            SacaStats.PubSub,
            "favorite_event:#{favorite.discord_id}",
            {:favorite, favorite}
          )

          redirect(conn, to: return_path)

        {:error, _changeset} ->
          conn
          |> put_flash(:error, "An error occured while adding #{name} to the database.")
          |> redirect(to: return_path)
      end
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
      query = from(f in Favorite, where: f.discord_id == ^user_id and f.character_id == ^id)
      favorite = Repo.one!(query)
      # Remove from DB.
      case Repo.delete(favorite) do
        {:ok, favorite} ->
          PubSub.broadcast(
            SacaStats.PubSub,
            "unfavorite_event:#{favorite.discord_id}",
            {:unfavorite, favorite}
          )

          redirect(conn, to: return_path)

        {:error, _changeset} ->
          conn
          |> put_flash(:error, "An error occured while removing #{name} from the database.")
          |> redirect(to: return_path)
      end
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
    with {:ok, %Character{} = char} <- Characters.get_by_name(name),
         {:ok, %OnlineStatus{} = status} <- OnlineStatus.get_by_id(char.character_id),
         status_text <- OnlineStatus.status_text(status) do
      user_id = if is_nil(conn.assigns.user), do: nil, else: conn.assigns.user.id
      assigns = build_assigns(char, status_text, stat_type, user_id)
      render(conn, "template.html", assigns)
    else
      :not_found ->
        conn
        |> put_flash(
          :error,
          "Could not find a character called '#{name}'. Make sure it's spelled correctly, then try again"
        )
        |> redirect(to: "/character")

      :error ->
        Logger.error("Error fetching character '#{name}'.")

        conn
        |> put_flash(
          :error,
          "We are unable to get that character right now. Please try again soon."
        )
        |> redirect(to: "/character")
    end
  end

  defp build_assigns(%Character{} = char, status, "sessions", user_id) do
    sessions = Session.get_summary(char.name_first_lower)

    [
      character_info: char,
      online_status: status,
      stat_page: "sessions.html",
      sessions: sessions,
      is_favorite: is_favorite?(char.character_id, user_id),
      changeset: Favorite.changeset(%Favorite{})
    ]
  end

  defp build_assigns(%Character{} = char, status, "weapons", user_id) do
    complete_weapons = Weapons.compile_stats(char.weapon_stat, char.weapon_stat_by_faction)
    type_set = Weapons.get_sorted_set_of_items("category", complete_weapons)
    category_set = Weapons.get_sorted_set_of_items("sanction", complete_weapons)

    [
      character_info: char,
      online_status: status,
      stat_page: "weapons.html",
      weapons: complete_weapons,
      types: type_set,
      categories: category_set,
      is_favorite: is_favorite?(char.character_id, user_id),
      changeset: Favorite.changeset(%Favorite{})
    ]
  end

  defp build_assigns(%Character{} = char, status, "general", user_id) do
    compiled_stats = Weapons.compile_stats(char.weapon_stat, char.weapon_stat_by_faction)
    all_medal_counts = Weapons.medal_counts(compiled_stats)
    best_weapons = Weapons.compile_best_stats(compiled_stats)

    ethnicity = Characters.get_ethnicity(char.faction_id, char.head_id)
    sex = Characters.get_sex(char.faction_id, char.head_id)

    character_characteristics = %{
      "ethnicity" => ethnicity,
      "sex" => sex
    }

    outfit_leader_name =
      case Characters.get_by_id(char.outfit.leader_character_id) do
        {:ok, %Character{} = character} ->
          character.name_first

        _ ->
          "Unknown Outfit Leader Name (ID #{char.outfit.leader_character_id})"
      end

    [
      character_info: char,
      online_status: status,
      outfit_leader_name: outfit_leader_name,
      all_medal_counts: all_medal_counts,
      stat_page: "general.html",
      character_characteristics: character_characteristics,
      best_weapons: best_weapons,
      is_favorite: is_favorite?(char.character_id, user_id),
      changeset: Favorite.changeset(%Favorite{})
    ]
  end

  defp build_assigns(%Character{} = char, status, stat_type, user_id) do
    [
      character_info: char,
      online_status: status,
      stat_page: stat_type <> ".html",
      is_favorite: is_favorite?(char.character_id, user_id),
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
end
