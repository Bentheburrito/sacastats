defmodule SacaStatsWeb.CharacterLive.Search do
  @moduledoc """
  LiveView for searching characters.
  """
  use SacaStatsWeb, :live_view
  use Phoenix.HTML
  import Ecto.Query

  alias Phoenix.PubSub
  alias SacaStats.Characters
  alias SacaStats.Census.OnlineStatus
  alias SacaStats.Events.{PlayerLogin, PlayerLogout}

  alias SacaStats.Character.Favorite
  alias SacaStats.Repo

  def render(assigns) do
    Phoenix.View.render(SacaStatsWeb.CharacterView, "lookup.html", assigns)
  end

  def mount(_params, session, socket) do
    # {:ok, %QueryResult{data: %{"name" => %{"first" => leader_name}}}} =
    #   Query.new(collection: "character")
    #   |> term("character_id", leader)
    #   |> show(["name"])
    #   |> PS2.API.query_one(SacaStats.sid())
    # with {:ok, info} <- CensusCache.get(SacaStats.CharacterCache, name),
    #      {:ok, status} <- CensusCache.get(SacaStats.OnlineStatusCache, info["character_id"]) do
    #   assigns = build_assigns(info, status, stat_type)
    #   render(conn, "template.html", assigns)

    # subscribe ot PubSub event
    # PubSub.subscribe(SacaStats.PubSub ..., "favorite_event:character_id")

    user = session["user"] || session[:user]

    if not is_nil(user) do
      PubSub.subscribe(SacaStats.PubSub, "favorite_event:#{user.id}")
      PubSub.subscribe(SacaStats.PubSub, "unfavorite_event:#{user.id}")
    end

    favorite_characters = get_favorite_users(user)

    {:ok,
     socket
     |> assign(:favorite_characters, favorite_characters)
     |> assign(:user, session["user"] || session[:user])}
  end

  defp get_favorite_users(nil), do: %{}

  defp get_favorite_users(user) do
    # if is_nil(user) || is_nil(user["id"]) do
    #   []
    # else
    # cs =
    #   SacaStats.Character.Favorite.changeset(%SacaStats.Character.Favorite{}, %{
    #     "discord_id" => 206091499706908673,
    #     "character_id" => 5429281854933028721,
    #     "last_known_name" => "HeartBrain"
    #   })

    #   case Ecto.Query.from(f in Favorite, select: f, where: f.discord_id == ^user["id"])
    #        |> Repo.all() do
    #     nil ->
    #       []

    #     [head | tail] ->
    #       characters = [head | tail]

    #       characters
    #       |> Stream.map(fn %Favorite{character_id: id} ->
    #         {CensusCache.get(OnlineStatusCache, id), id}
    #       end)
    #       |> Enum.group_by(
    #         fn {{:ok, online_status}, _id} -> online_status end,
    #         fn {_online_status, id} -> id end
    #       )
    #       |> Stream.map(fn {online_status, ids} -> {online_status, Enum.sort(ids)} end)
    #       |> Enum.into(%{})
    #   end
    # end

    favorites_result =
      Ecto.Query.from(f in Favorite, select: f, where: f.discord_id == ^user.id) |> Repo.all()

    # If the list is empty (i.e. no favorites), return an empty map
    if match?([], favorites_result) do
      %{}
    else
      favorite_characters = Map.new(favorites_result, &{&1.character_id, &1})

      favorite_character_ids = Map.keys(favorite_characters)

      {:ok, character_infos} = Characters.get_many_by_id(favorite_character_ids)

      {:ok, online_status_map} = OnlineStatus.get_many_by_id(favorite_character_ids)

      character_infos
      |> Enum.reduce(%{}, fn
        {character_id, :not_found}, acc ->
          {:ok, favorite_character} = Map.fetch(favorite_characters, character_id)
          name = favorite_character.last_known_name

          status =
            case Map.get(online_status_map, character_id) do
              {:ok, status} -> OnlineStatus.status_text(status)
              _ -> "unknown"
            end

          PubSub.subscribe(SacaStats.PubSub, "game_event:#{character_id}")

          card_info = %{
            "name" => favorite_character.last_known_name,
            "id" => favorite_character.character_id,
            "outfit" => "",
            "rank" => "Status Not Found",
            "faction_id" => 0,
            "online_status" => status
          }

          Map.update(acc, status, %{character_id => card_info}, fn character_infos ->
            Map.put(
              character_infos,
              character_id,
              card_info
            )
          end)

        {character_id, {:ok, character}}, acc ->
          # check if value.name.first is different than last_known_name
          character.name_first |> IO.inspect(label: "who")

          status =
            case Map.get(online_status_map, character_id) do
              {:ok, status} -> OnlineStatus.status_text(status)
              _ -> :not_found
            end

          {:ok, favorite_character} = Map.fetch(favorite_characters, character_id)
          favorite_character.last_known_name |> IO.inspect(label: "last_known")

          PubSub.subscribe(SacaStats.PubSub, "game_event:#{character_id}")

          card_info = %{
            "name" => character.name_first,
            "id" => character_id,
            "outfit" => character.outfit.name,
            "rank" =>
              SacaStats.Utils.get_rank_string(
                character.battle_rank,
                character.prestige_level
              ),
            "faction_id" => character.faction_id,
            "online_status" => status
          }

          Map.update(acc, status, %{character_id => card_info}, fn character_infos ->
            Map.put(
              character_infos,
              character_id,
              card_info
            )
          end)
      end)
      |> IO.inspect(label: "Favorite_Characters")
    end
  end

  # A favorite character has gone online
  def handle_info(
        %Ecto.Changeset{data: %PlayerLogin{}} = event_cs,
        socket
      ) do
    %PlayerLogin{character_id: character_id} = Ecto.Changeset.apply_changes(event_cs)

    {login_char_info, updated_char_map} =
      pop_in(socket.assigns.favorite_characters, ["offline", character_id])

    updated_char_map =
      Map.update(
        updated_char_map,
        "online",
        %{character_id => login_char_info},
        &Map.put(&1, character_id, login_char_info)
      )

    updated_socket = assign(socket, :favorite_characters, updated_char_map)

    {:noreply, updated_socket}
  end

  def handle_info(
        %Ecto.Changeset{data: %PlayerLogout{}} = event_cs,
        socket
      ) do
    %PlayerLogout{character_id: character_id} = Ecto.Changeset.apply_changes(event_cs)

    {logout_char_info, updated_char_map} =
      pop_in(socket.assigns.favorite_characters, ["online", character_id])

    updated_char_map =
      Map.update(
        updated_char_map,
        "offline",
        %{character_id => logout_char_info},
        &Map.put(&1, character_id, logout_char_info)
      )

    updated_socket = assign(socket, :favorite_characters, updated_char_map)

    {:noreply, updated_socket}
  end

  # --------------------------------------------------------------------------------------------------------------------------------------Re apply js listeners on page update
  # If someone favorites a character in another window, this is the fn that receives that character to add to the assigns
  def handle_info(%Favorite{} = favorite, socket) do
    # {:ok, favorite_character_info} =
    #   SacaStats.CensusCache.get(SacaStats.CharacterCache, favorite.character_id)

    # character_info = %{
    #   "name" => favorite_character_info["name"]["first"],
    #   "id" => favorite.character_id,
    #   "outfit" => favorite_character_info["outfit"]["name"],
    #   "rank" =>
    #     SacaStats.Utils.get_rank_string(
    #       favorite_character_info["battle_rank"]["value"],
    #       favorite_character_info["prestige_level"]
    #     ),
    #   "faction_id" => favorite_character_info["faction_id"],
    #   "online_status" => "online"
    # }

    # updated_char_map =
    #   socket.assigns.favorite_characters
    #   |> Map.update!("online", fn char_list ->
    #     Enum.reject(char_list, fn char -> char["id"] == favorite.character_id end)
    #   end)
    #   |> Map.update!("offline", fn char_list ->
    #     Enum.reject(char_list, fn char -> char["id"] == favorite.character_id end)
    #   end)
    #   |> Map.update!("unknown", fn char_list ->
    #     Enum.reject(char_list, fn char -> char["id"] == favorite.character_id end)
    #   end)
    updated_char_map = get_favorite_users(socket.assigns.user)

    {:noreply,
     socket
     |> assign(:favorite_characters, updated_char_map)}
  end

  # If someone unfavorites a character in another window, this is the fn that receives that character to remove to the assigns
  def handle_info(%Favorite{} = favorite, socket) do
    # {:ok, favorite_character_info} =
    #   SacaStats.CensusCache.get(SacaStats.CharacterCache, favorite.character_id)

    # character_info = %{
    #   "name" => favorite_character_info["name"]["first"],
    #   "id" => favorite.character_id,
    #   "outfit" => favorite_character_info["outfit"]["name"],
    #   "rank" =>
    #     SacaStats.Utils.get_rank_string(
    #       favorite_character_info["battle_rank"]["value"],
    #       favorite_character_info["prestige_level"]
    #     ),
    #   "faction_id" => favorite_character_info["faction_id"],
    #   "online_status" => "online"
    # }

    # updated_char_map =
    #   socket.assigns.favorite_characters
    #   |> Map.update!("online", fn char_list ->
    #     [character_info | char_list]
    #   end)
    #   |> Map.update!("offline", fn char_list ->
    #     Enum.reject(char_list, fn char -> char["id"] == favorite.character_id end)
    #   end)
    #   |> Map.update!("unknown", fn char_list ->
    #     Enum.reject(char_list, fn char -> char["id"] == favorite.character_id end)
    #   end)

    updated_char_map = get_favorite_users(socket.assigns.user)

    {:noreply,
     socket
     |> assign(:favorite_characters, updated_char_map)}
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
      <%= if is_map(characters) && map_size(characters) > 0 do %>
        <div class="status-card-section-header" data-bs-toggle="collapse" type="button" data-bs-target={"##{section_type}collapsable"}>
          <h2 class="d-inline"><%=  String.capitalize(section_type)%></h2><p class="favorite-character-status-contains d-inline">(<%= map_size(characters) %>)</p>
          <h2 class="float-right arrow-pointer"><i class="fa fa-chevron-up flip" style="font-size:24px"></i></h2>
        </div>
        <hr class="mt-3" />
        <div class="collapse show" id={"#{section_type}collapsable"}>
          <div class="row justify-content-center pb-5">
            <%= for character <- characters do %>
              <%= encode_character_card(assigns, character, section_type) %>
            <% end %>
          </div>
        </div>
      <% end %>
    """
  end

  defp encode_character_card(assigns, {_character_id, character}, online_status) do
    name = Map.get(character, "name")
    id = Map.get(character, "id")
    outfit = Map.get(character, "outfit", "")
    rank = Map.get(character, "rank")
    faction_id = Map.get(character, "faction_id")

    ~H"""
      <div id={name <> "-character-status-card"}
          class={"col-12 col-md-6 col-lg-4 col-xl-3 border rounded py-3 px-0 mx-0 mx-md-3 my-2 " <> (Map.get(SacaStats.factions, SacaStats.Utils.maybe_to_int(faction_id))[:alias] |> String.downcase()) <> "-character-status-card character-status-card"}>
        <%= encode_character_remove_button_mobile(assigns, id, online_status) %>
        <%= encode_character_remove_button(assigns, id, name, online_status) %>
        <div class="row flex-row h-100">
          <%= encode_character_faction_image(assigns, name, faction_id) %>
          <%= encode_character_characteristics(assigns, name, outfit, rank) %>
          <%= encode_character_online_status(assigns, online_status) %>
        </div>
      </div>
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
        <%= if(faction_id != 0) do %>
          <img class="float-md-left float-none" data-toggle="tooltip"
              title={name <> " plays on the " <> Map.get(SacaStats.factions, SacaStats.Utils.maybe_to_int(faction_id))[:name]}
              src={Map.get(SacaStats.factions, SacaStats.Utils.maybe_to_int(faction_id))[:image]}
              alt={Map.get(SacaStats.factions, SacaStats.Utils.maybe_to_int(faction_id))[:name] <> "'s banner"} width="60">
        <% end %>
      </div>
    """
  end

  defp encode_character_characteristics(assigns, name, outfit, rank) do
    ~H"""
      <div class="col-8 pl-5">
        <div class="row pl-3">
          <div class="col-12 px-0">
            <h2 class="mb-0"><%= name %></h2>
          </div>
        </div>
        <div class="row pl-3">
          <div class="col-12 px-0">
            <p class="mb-0 small"><%= outfit %></p>
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
