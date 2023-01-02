defmodule SacaStatsWeb.CharacterLive.Search do
  @moduledoc """
  LiveView for searching characters.
  """
  use SacaStatsWeb, :live_view
  use Phoenix.HTML
  import Ecto.Query

  require Logger

  alias Phoenix.PubSub
  alias SacaStats.Characters
  alias SacaStats.Census.{Character, OnlineStatus}
  alias SacaStats.Events.{PlayerLogin, PlayerLogout}

  alias SacaStats.Character.Favorite
  alias SacaStats.Repo

  def render(assigns) do
    Phoenix.View.render(SacaStatsWeb.CharacterView, "lookup.html", assigns)
  end

  def mount(_params, session, socket) do
    user = session["user"] || session[:user]

    if not is_nil(user) do
      PubSub.subscribe(SacaStats.PubSub, "favorite_event:#{user.id}")
      PubSub.subscribe(SacaStats.PubSub, "unfavorite_event:#{user.id}")
    end

    # either :error or map of favorite characters
    favorite_characters =
      case get_favorite_users(user) do
        {:ok, fav_chars} ->
          fav_chars

        :error ->
          :error
      end

    {:ok,
     socket
     |> assign(:favorite_characters, favorite_characters)
     |> assign(:user, session["user"] || session[:user])}
  end

  defp get_favorite_users(nil), do: %{}

  defp get_favorite_users(user) do
    favorites_result =
      Ecto.Query.from(f in Favorite, select: f, where: f.discord_id == ^user.id) |> Repo.all()

    # If the list is empty (i.e. no favorites), return an empty map
    if match?([], favorites_result) do
      %{}
    else
      favorite_characters = Map.new(favorites_result, &{&1.character_id, &1})

      favorite_character_ids = Map.keys(favorite_characters)

      with {:ok, character_infos} <-
             Characters.get_many_by_id(favorite_character_ids, _shallow = true),
           {:ok, online_status_map} <- OnlineStatus.get_many_by_id(favorite_character_ids) do
        {:ok, group_favorites(character_infos, favorite_characters, online_status_map)}
      end
    end
  end

  defp group_favorites(
         character_infos,
         favorite_characters,
         online_status_map
       ) do
    Enum.reduce(character_infos, %{}, fn {character_id, maybe_character}, acc ->
      {:ok, %Favorite{} = favorite_character} = Map.fetch(favorite_characters, character_id)

      status =
        case Map.get(online_status_map, character_id) do
          {:ok, status} -> OnlineStatus.status_text(status)
          _ -> :not_found
        end

      PubSub.subscribe(SacaStats.PubSub, "game_event:#{character_id}")

      card_info =
        case maybe_character do
          {:ok, %Character{} = character} ->
            update_character_last_known_name_in_repo(favorite_character, character)

            %{
              "name" => character.name_first,
              "id" => character_id,
              "rank" =>
                SacaStats.Utils.get_rank_string(
                  character.battle_rank,
                  character.prestige_level
                ),
              "faction_id" => character.faction_id,
              "online_status" => status
            }

          :not_found ->
            %{
              "name" => favorite_character.last_known_name,
              "id" => favorite_character.character_id,
              "rank" => "Status Not Found",
              "faction_id" => 0,
              "online_status" => status
            }
        end

      Map.update(acc, status, %{character_id => card_info}, fn character_infos ->
        Map.put(
          character_infos,
          character_id,
          card_info
        )
      end)
    end)
  end

  defp update_character_last_known_name_in_repo(favorite_character, character) do
    # Update the last known name in our DB if it's changed
    if character.name_first != favorite_character.last_known_name do
      update_repo(
        favorite_character,
        character,
        Favorite.changeset(favorite_character, %{
          "last_known_name" => character.name_first
        })
      )
    end
  end

  defp update_repo(favorite_character, character, changeset) do
    case Repo.update(changeset) do
      {:ok, _updated_favorite} ->
        nil

      {:error, changeset} ->
        Logger.error(
          "Unable to update last known favorite character name (#{favorite_character.last_known_name} -> #{character.name_first}): #{inspect(changeset)}"
        )
    end
  end

  # A favorite character logs on
  def handle_info(
        %Ecto.Changeset{data: %PlayerLogin{}} = event_cs,
        socket
      ) do
    %PlayerLogin{character_id: character_id} = Ecto.Changeset.apply_changes(event_cs)

    {login_char_info, updated_char_map} =
      pop_in(socket.assigns.favorite_characters, ["offline", character_id])

    updated_char_map =
      if is_nil(login_char_info) do
        updated_char_map
      else
        Map.update(
          updated_char_map,
          "online",
          %{character_id => login_char_info},
          &Map.put(&1, character_id, login_char_info)
        )
      end

    {:noreply,
     assign(
       push_event(socket, "character_card_change", %{}),
       :favorite_characters,
       updated_char_map
     )}
  end

  # A favorite character logs off
  def handle_info(
        %Ecto.Changeset{data: %PlayerLogout{}} = event_cs,
        socket
      ) do
    %PlayerLogout{character_id: character_id} = Ecto.Changeset.apply_changes(event_cs)

    {logout_char_info, updated_char_map} =
      pop_in(socket.assigns.favorite_characters, ["online", character_id])

    updated_char_map =
      if is_nil(logout_char_info) do
        updated_char_map
      else
        Map.update(
          updated_char_map,
          "offline",
          %{character_id => logout_char_info},
          &Map.put(&1, character_id, logout_char_info)
        )
      end

    {:noreply,
     assign(
       push_event(socket, "character_card_change", %{}),
       :favorite_characters,
       updated_char_map
     )}
  end

  # The user favorites a character in another window
  def handle_info({:favorite, %Favorite{} = favorite}, socket) do
    with {:ok, %Character{} = info} <- Characters.get_by_id(favorite.character_id),
         {:ok, %OnlineStatus{} = status} <- OnlineStatus.get_by_id(favorite.character_id) do
      status = OnlineStatus.status_text(status)

      PubSub.subscribe(SacaStats.PubSub, "game_event:#{favorite.character_id}")

      card_info = %{
        "name" => info.name_first,
        "id" => info.character_id,
        "rank" =>
          SacaStats.Utils.get_rank_string(
            info.battle_rank,
            info.prestige_level
          ),
        "faction_id" => info.faction_id,
        "online_status" => status
      }

      updated_char_map =
        Map.update(
          socket.assigns.favorite_characters,
          status,
          %{info.character_id => card_info},
          &Map.put(&1, info.character_id, card_info)
        )

      {:noreply,
       socket
       |> push_event("character_card_change", %{})
       |> assign(
         :favorite_characters,
         updated_char_map
       )}
    else
      error when error in [:not_found, :error] ->
        {:noreply,
         put_flash(
           socket,
           :error,
           "We detected a new favorited character, but something went wrong."
         )}
    end
  end

  # The user unfavorites a character in another window
  def handle_info({:unfavorite, %Favorite{} = favorite}, socket) do
    PubSub.unsubscribe(SacaStats.PubSub, "game_event:#{favorite.character_id}")

    updated_char_map =
      Enum.reduce_while(socket.assigns.favorite_characters, nil, fn {status, char_map}, _ ->
        if is_map_key(char_map, favorite.character_id) do
          {_, updated_char_map} =
            pop_in(socket.assigns.favorite_characters, [status, favorite.character_id])

          {:halt, updated_char_map}
        else
          {:cont, nil}
        end
      end)

    {:noreply, assign(socket, :favorite_characters, updated_char_map)}
  end

  def handle_event("remove_favorite_character", %{"id" => char_id_and_status}, socket) do
    user = socket.assigns.user
    [char_id_str, status] = String.split(char_id_and_status, ":")
    char_id = String.to_integer(char_id_str)

    Repo.delete_all(
      from(f in Favorite, where: f.discord_id == ^user.id and f.character_id == ^char_id)
    )

    {_, updated_char_map} =
      socket.assigns.favorite_characters
      |> pop_in([status, char_id])

    updated_socket = assign(socket, :favorite_characters, updated_char_map)

    {:noreply, updated_socket}
  end

  def create_character_status_cards(assigns, characters) do
    online_characters = Map.get(characters, "online", %{})
    offline_characters = Map.get(characters, "offline", %{})
    no_status_characters = Map.get(characters, "unknown", %{})

    if map_size(online_characters) + map_size(offline_characters) + map_size(no_status_characters) >
         0 do
      ~H"""
        <%= encode_character_status_card_section(assigns, online_characters, "online") %>
        <%= encode_character_status_card_section(assigns, offline_characters, "offline") %>
        <%= encode_character_status_card_section(assigns, no_status_characters, "unknown") %>
      """
    else
      ~H"""
        <p class="text-center">You currently have no favorite characters.<br/>Favorite a character by visiting their page and adding them</p>
      """
    end
  end

  defp encode_character_status_card_section(assigns, characters, section_type) do
    ~H"""
      <%= if is_map(characters) and map_size(characters) > 0 do %>
        <div class="status-card-section-header" data-bs-toggle="collapse" type="button" data-bs-target={"##{section_type}collapsable"}>
          <h2 class="d-inline"><%=  String.capitalize(section_type)%></h2><p class="favorite-character-status-contains d-inline">(<%= map_size(characters) %>)</p>
          <h2 class="float-right arrow-pointer"><i class="fa fa-chevron-up flip" style="font-size:24px"></i></h2>
        </div>
        <hr class="mt-3" />
        <div class="collapse show" id={"#{section_type}collapsable"}>
          <div class="row justify-content-center pb-5">
            <%= for sorted_character <- get_sorted_character_ids(characters) do %>
              <% character = characters[sorted_character.id] %>
              <%= encode_character_card(assigns, character, section_type) %>
            <% end %>
          </div>
        </div>
      <% end %>
    """
  end

  defp get_sorted_character_ids(characters) do
    for {character_id, favorite_info} <- characters do
      %{id: character_id, name: String.downcase(favorite_info["name"])}
    end
    |> Enum.sort_by(&Map.fetch(&1, :name))
  end

  defp encode_character_card(assigns, character, online_status) do
    name = Map.get(character, "name")
    id = Map.get(character, "id")
    rank = Map.get(character, "rank")
    faction_id = Map.get(character, "faction_id")

    ~H"""
      <a id={name <> "-character-status-card"} href={"/character/#{name}"}
          class={"col-12 col-md-6 col-lg-4 col-xl-3 border rounded py-3 px-0 mx-0 mx-md-3 my-2 " <> (Map.get(SacaStats.factions, SacaStats.Utils.maybe_to_int(faction_id))[:alias] |> String.downcase()) <> "-character-status-card character-status-card"}>
        <%= encode_character_remove_button_mobile(assigns, id, online_status) %>
        <%= encode_character_remove_button(assigns, id, name, online_status) %>
        <div class="row flex-row h-100">
          <%= encode_character_faction_image(assigns, name, faction_id) %>
          <%= encode_character_characteristics(assigns, name, rank) %>
          <%= encode_character_online_status(assigns, online_status) %>
        </div>
      </a>
    """
  end

  defp encode_character_remove_button_mobile(assigns, id, online_status) do
    ~H"""
      <div class="character-status-card-removal-button-mobile-container w-100 h-100 d-none">
        <button id={"#{id}-character-status-card-removal-button-mobile"} phx-click="remove_favorite_character" phx-value-id={"#{id}:#{online_status}"}
              class="btn btn-danger character-status-card-removal-button-mobile">
          <i class="fas fa-trash"></i> Remove
        </button>
      </div>
    """
  end

  defp encode_character_remove_button(assigns, id, name, online_status) do
    ~H"""
      <button id={"#{id}-character-status-card-removal-button"} phx-click="remove_favorite_character" phx-value-id={"#{id}:#{online_status}"}
            class="btn btn-danger my-0 py-1 px-3 ml-5 d-none character-status-card-removal-button"
            title={"Remove " <> name <> " from favorites"}>
        <i class="fas fa-trash"></i>
      </button>
    """
  end

  defp encode_character_faction_image(assigns, name, faction_id) do
    ~H"""
      <div class="col-2 d-flex align-items-center">
        <%= if faction_id != 0 do %>
          <img class="float-md-left float-none" data-toggle="tooltip"
              title={name <> " plays on the " <> Map.get(SacaStats.factions, SacaStats.Utils.maybe_to_int(faction_id))[:name]}
              src={Map.get(SacaStats.factions, SacaStats.Utils.maybe_to_int(faction_id))[:image]}
              alt={Map.get(SacaStats.factions, SacaStats.Utils.maybe_to_int(faction_id))[:name] <> "'s banner"} width="60">
        <% end %>
      </div>
    """
  end

  defp encode_character_characteristics(assigns, name, rank) do
    ~H"""
      <div class="col-8 pl-5">
        <div class="row pl-3">
          <div class="col-12 px-0">
            <h2 class="mb-0 favorite-character-card-name"><%= name %></h2>
          </div>
        </div>
        <div class="row pl-3">
          <div class="col-12 px-0">
            <h4 class="mb-0"><%= rank %></h4>
          </div>
        </div>
      </div>
    """
  end

  defp encode_character_online_status(assigns, online_status) do
    ~H"""
      <%= if online_status in ["online", "offline"] do %>
        <div class="col-1 d-flex align-items-center">
          <img src={"/images/character/" <> online_status <> ".ico"} alt={online_status} width="30">
        </div>
      <% end %>
    """
  end
end
