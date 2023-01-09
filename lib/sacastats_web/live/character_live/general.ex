defmodule SacaStatsWeb.CharacterLive.General do
  @moduledoc """
  LiveView for a character's general stats page.
  """
  use SacaStatsWeb, :live_view

  require Logger

  alias Phoenix.PubSub
  alias SacaStats.Census.Character.Outfit
  alias SacaStats.Character.Favorite
  alias SacaStats.{Characters, Weapons}
  alias SacaStats.Census.{Character, OnlineStatus}
  alias SacaStats.Events.{PlayerLogin, PlayerLogout}

  @init_assigns %{
    character_info: %Character{
      head_id: 0,
      profile_type_description: "Light Assault",
      battle_rank: :loading,
      available_points: :loading
    },
    online_status: "loading",
    outfit_leader_name: :loading,
    all_medal_counts: %{},
    stat_page: "general.html",
    character_characteristics: %{"ethnicity" => "robot", "sex" => "robot"},
    best_weapons: %{"Loading..." => %{}},
    favorited?: :loading,
    changeset: :loading
  }

  def render(assigns) do
    Phoenix.View.render(
      SacaStatsWeb.CharacterView,
      "template.html",
      Map.put(assigns, :stat_page, "general.html")
    )
  end

  def handle_params(_unsigned_params, uri, socket) do
    {:noreply, assign(socket, request_path: URI.parse(uri).path)}
  end

  def mount(%{"character_name" => name}, session, socket) do
    socket =
      if connected?(socket) do
        try_build_content(name, socket)
      else
        assign(socket, @init_assigns)
      end

    {:ok, assign(socket, :user, session["user"])}
  end

  defp try_build_content(character_name, socket) do
    with {:ok, %Character{} = char} <- Characters.get_by_name(character_name) do
      # Start tasks to do some work concurrently
      online_status_task = Task.async(fn -> OnlineStatus.get_by_id(char.character_id) end)
      user_id = socket.assigns[:user][:id]
      favorited_task = Task.async(fn -> Characters.favorite?(char.character_id, user_id) end)

      # Subscribe to events from this character
      PubSub.subscribe(SacaStats.PubSub, "game_event:#{char.character_id}")

      # Compile weapon stats
      compiled_stats = Weapons.compile_stats(char.weapon_stat, char.weapon_stat_by_faction)
      all_medal_counts = Weapons.medal_counts(compiled_stats)
      best_weapons = Weapons.compile_best_stats(compiled_stats)

      # Get additional character info
      ethnicity = Characters.get_ethnicity(char.faction_id, char.head_id)
      sex = Characters.get_sex(char.faction_id, char.head_id)

      character_characteristics = %{
        "ethnicity" => ethnicity,
        "sex" => sex
      }

      outfit_leader_name =
        with %Outfit{leader_character_id: leader_char_id} <- char.outfit,
             {:ok, %Character{name_first: name}} <- Characters.get_by_id(leader_char_id) do
          name
        else
          _ -> "Unknown Outfit Leader Name (ID #{char.outfit.leader_character_id})"
        end

      # Await tasks
      status_text =
        case Task.await(online_status_task) do
          {:ok, %OnlineStatus{} = status} -> OnlineStatus.status_text(status)
          _ -> "unknown"
        end

      favorited? = Task.await(favorited_task)

      # Assign data to socket and return
      assign(socket,
        character_info: char,
        online_status: status_text,
        outfit_leader_name: outfit_leader_name,
        all_medal_counts: all_medal_counts,
        stat_page: "general.html",
        character_characteristics: character_characteristics,
        best_weapons: best_weapons,
        favorited?: favorited?,
        changeset: Favorite.changeset(%Favorite{})
      )
    else
      :not_found ->
        socket
        |> put_flash(
          :error,
          "Could not find a character called '#{character_name}'. Make sure it's spelled correctly, then try again"
        )
        |> live_redirect(to: Routes.live_path(socket, CharacterLive.Search))

      :error ->
        Logger.error("Error fetching character '#{character_name}'.")

        socket
        |> put_flash(
          :error,
          "We are unable to get that character right now. Please try again soon."
        )
        |> live_redirect(to: Routes.live_path(socket, CharacterLive.Search))
    end
  end

  # A favorite character logs on
  def handle_info(
        %Ecto.Changeset{data: %PlayerLogin{}},
        socket
      ) do
    {:noreply,
     assign(
       socket,
       :online_status,
       "online"
     )}
  end

  # This character logs off
  def handle_info(
        %Ecto.Changeset{data: %PlayerLogout{}},
        socket
      ) do
    {:noreply,
     assign(
       socket,
       :online_status,
       "offline"
     )}
  end

  # Catch-all for other kinds of player events
  def handle_info(
        %Ecto.Changeset{},
        socket
      ) do
    {:noreply, socket}
  end
end
