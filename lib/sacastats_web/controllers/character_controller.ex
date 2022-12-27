require Logger

defmodule SacaStatsWeb.CharacterController do
  use SacaStatsWeb, :controller

  alias SacaStats.{Characters, Weapons}
  alias SacaStats.Census.{Character, OnlineStatus}
  alias SacaStats.Session

  def base(conn, %{"character_name" => _name}) do
    redirect(conn, to: conn.request_path <> "/general")
  end

  def search(conn, _params) do
    render(conn, "lookup.html")
  end

  def character(%Plug.Conn{} = conn, %{"character_name" => name, "stat_type" => stat_type}) do
    with {:ok, %Character{} = char} <- Characters.get_by_name(name),
         {:ok, %OnlineStatus{} = status} <- OnlineStatus.get_by_id(char.character_id),
         status_text <- OnlineStatus.status_text(status) do
      assigns = build_assigns(char, status_text, stat_type)
      render(conn, "template.html", assigns)
    else
      :not_found ->
        conn
        |> put_flash(
          :error,
          "Could not find a character called '#{name}'. Make sure it's spelled correctly, then try again"
        )
        |> redirect(to: Routes.character_path(conn, :search))

      :error ->
        Logger.error("Error fetching character '#{name}'.")

        conn
        |> put_flash(
          :error,
          "We are unable to get that character right now. Please try again soon."
        )
        |> redirect(to: Routes.character_path(conn, :search))
    end
  end

  defp build_assigns(%Character{} = char, status, "sessions") do
    sessions = Session.get_summary(char.name_first_lower)

    [
      character_info: char,
      online_status: status,
      stat_page: "sessions.html",
      sessions: sessions
    ]
  end

  defp build_assigns(%Character{} = char, status, "weapons") do
    complete_weapons = Weapons.compile_stats(char.weapon_stat, char.weapon_stat_by_faction)
    type_set = Weapons.get_sorted_set_of_items("category", complete_weapons)
    category_set = Weapons.get_sorted_set_of_items("sanction", complete_weapons)

    [
      character_info: char,
      online_status: status,
      stat_page: "weapons.html",
      weapons: complete_weapons,
      types: type_set,
      categories: category_set
    ]
  end

  defp build_assigns(%Character{} = char, status, "general") do
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
      best_weapons: best_weapons
    ]
  end

  defp build_assigns(%Character{} = info, status, stat_type) do
    [
      character_info: info,
      online_status: status,
      stat_page: stat_type <> ".html"
    ]
  end
end
