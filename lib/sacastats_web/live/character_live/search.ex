defmodule SacaStatsWeb.CharacterLive.Search do
  @moduledoc """
  LiveView for searching characters.
  """
  use SacaStatsWeb, :live_view
  use Phoenix.HTML
  import Ecto.Query

  import PS2.API.QueryBuilder
  alias PS2.API.{Query, QueryResult}
  alias SacaStats.{CensusCache, OnlineStatusCache, Session}

  alias SacaStats.Repo
  alias SacaStats.Character.Favorite

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

    user = session["user"] || session[:user]

    favorite_characters = get_favorite_users(user)

    {:ok,
     socket
     |> assign(:favorite_characters, favorite_characters)
     |> assign(:user, session["user"] || session[:user])}
  end

  defp get_favorite_users(user) do
    # if is_nil(user) || is_nil(user["id"]) do
    #   []
    # else
    #   # cs = SacaStats.Character.Favorite.changeset(%SacaStats.Character.Favorite{}, %{"discord_id" => 206091499706908673, "character_id" => 5429281854933028721, "last_known_name" => "HeartBrain"})

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

    %{
      "online" => [
        %{
          "name" => "dndmackey",
          "id" => "5428085256239782129",
          "outfit" => "The Sacagaweas",
          "rank" => "ASP 2 BR 72",
          "faction_id" => 1
        },
        %{
          "name" => "RedCoats24",
          "id" => "5428123302640594129",
          "outfit" => "The Hakagaweas",
          "rank" => "ASP 2 BR 20",
          "faction_id" => 3
        }
      ],
      "offline" => [
        %{
          "name" => "NSmackey",
          "id" => "5429150307164952145",
          "outfit" => "",
          "rank" => "BR 46",
          "faction_id" => 4
        },
        %{
          "name" => "Snowful ",
          "id" => "5428713425545165425",
          "outfit" => "Cerulean Unicorns",
          "rank" => "ASP 1 BR 95",
          "faction_id" => 2
        },
        %{
          "name" => "Snowful ",
          "id" => "5428713425545165425",
          "outfit" => "Cerulean Unicorns",
          "rank" => "ASP 1 BR 95",
          "faction_id" => 2
        },
        %{
          "name" => "Snowful ",
          "id" => "5428713425545165425",
          "outfit" => "Cerulean Unicorns",
          "rank" => "ASP 1 BR 95",
          "faction_id" => 2
        },
        %{
          "name" => "Snowful ",
          "id" => "5428713425545165425",
          "outfit" => "Cerulean Unicorns",
          "rank" => "ASP 1 BR 95",
          "faction_id" => 2
        },
        %{
          "name" => "Snowful ",
          "id" => "5428713425545165425",
          "outfit" => "Cerulean Unicorns",
          "rank" => "ASP 1 BR 95",
          "faction_id" => 2
        },
        %{
          "name" => "Snowful ",
          "id" => "5428713425545165425",
          "outfit" => "Cerulean Unicorns",
          "rank" => "ASP 1 BR 95",
          "faction_id" => 2
        }
      ]
    }
  end

  def create_character_status_cards(assigns, characters) do
    online_characters = Map.get(characters, "online")
    offline_characters = Map.get(characters, "offline")

    ~H"""
      <%= if(online_characters != nil && length(online_characters) > 0) do %>
        <h2 class="d-inline">Online</h2><p class="favorite-character-status-contains d-inline">(<%= length(online_characters) %>)</p>
        <hr/>
        <div class="row justify-content-center mb-5">
          <%= for character <- online_characters do %>
            <%= encode_character_card(assigns, character, "online") %>
          <% end %>
        </div>
      <% end %>
      <%= if(offline_characters != nil && length(offline_characters) > 0) do %>
        <h2 class="d-inline">Offline</h2><p class="favorite-character-status-contains d-inline">(<%= length(offline_characters) %>)</p>
        <hr/>
        <div class="row justify-content-center pb-5">
          <%= for character <- offline_characters do %>
            <%= encode_character_card(assigns, character, "offline") %>
          <% end %>
        </div>
        <% end %>
    """
  end

  defp encode_character_card(assigns, character, online_status) do
    name = Map.get(character, "name")
    id = Map.get(character, "id")
    outfit = Map.get(character, "outfit", "")
    rank = Map.get(character, "rank")
    faction_id = Map.get(character, "faction_id")

    ~H"""
      <div id={name <> "-character-status-card"}
          class={"col-12 col-md-6 col-lg-4 col-xl-3 border rounded py-3 px-0 mx-0 mx-md-3 my-2 " <> (Map.get(SacaStats.factions, SacaStats.Utils.maybe_to_int(faction_id))[:alias] |> String.downcase()) <> "-character-status-card character-status-card"}>
        <%= encode_character_remove_button_mobile(assigns, id, name) %>
        <%= encode_character_remove_button(assigns, id, name) %>
        <div class="row flex-row h-100">
          <%= encode_character_faction_image(assigns, name , faction_id) %>
          <%= encode_character_characteristics(assigns, name, outfit, rank) %>
          <%= encode_character_online_status(assigns, online_status) %>
        </div>
      </div>
    """
  end

  defp encode_character_remove_button_mobile(assigns, id, name) do
    ~H"""
      <div class="character-status-card-removal-button-mobile-container w-100 h-100 d-none">
        <button id={id <> "-character-status-card-removal-button-mobile"}
              class="btn btn-danger character-status-card-removal-button-mobile">
          <i class="fas fa-trash"></i> Remove
        </button>
      </div>
    """
  end

  defp encode_character_remove_button(assigns, id, name) do
    ~H"""
      <button id={id <> "-character-status-card-removal-button"}
            class="btn btn-danger my-0 py-1 px-3 ml-5 d-none character-status-card-removal-button"
            title={"Remove " <> name <> " from favorites"}>
        <i class="fas fa-trash"></i>
      </button>
    """
  end

  defp encode_character_faction_image(assigns, name, faction_id) do
    ~H"""
      <div class="col-2 d-flex align-items-center">
        <img class="float-md-left float-none" data-toggle="tooltip"
            title={name <> " plays on the " <> Map.get(SacaStats.factions, SacaStats.Utils.maybe_to_int(faction_id))[:name]}
            src={Map.get(SacaStats.factions, SacaStats.Utils.maybe_to_int(faction_id))[:image]}
            alt={Map.get(SacaStats.factions, SacaStats.Utils.maybe_to_int(faction_id))[:name] <> "'s banner"} width="60">
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
      <div class="col-1 d-flex align-items-center">
        <img src={"/images/character/" <> online_status <> ".ico"} alt={online_status} width="30">
      </div>
    """
  end
end
