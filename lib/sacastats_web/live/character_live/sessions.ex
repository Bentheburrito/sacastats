defmodule SacaStatsWeb.CharacterLive.Sessions do
  @moduledoc """
  LiveView for a character's general stats page.
  """
  use SacaStatsWeb, :live_view

  require Logger

  import Ecto.Query

  alias Phoenix.PubSub
  alias SacaStats.Census.Character.Outfit
  alias SacaStats.Character.Favorite
  alias SacaStats.{Characters, Weapons}
  alias SacaStats.Census.{Character, OnlineStatus}
  alias SacaStats.Events.{PlayerLogin, PlayerLogout}
  alias SacaStats.Repo

  @init_assigns %{
    character_info: %Character{
      head_id: 0,
      profile_type_description: "Light Assault",
      battle_rank: :loading,
      available_points: :loading
    },
    online_status: "loading",
    sessions: [],
    favorited?: false
  }

  def render(assigns) do
    Phoenix.View.render(
      SacaStatsWeb.CharacterView,
      "template.html",
      Map.put(assigns, :stat_page, "sessions.html")
    )
  end

  def handle_params(%{"character_name" => character_name}, uri, socket) do
    {:noreply, assign(socket, request_path: URI.parse(uri).path, character_name: character_name)}
  end

  def mount(%{"character_name" => name}, session, socket) do
    socket =
      if connected?(socket) do
        IO.inspect(socket.assigns, label: "HEY we're CONNECTED, assigns:")
        schedule_work(name, session, socket)
        socket
      else
        IO.inspect(socket.assigns, label: "HEY we're **NOT** CONNECTED, assigns:")
        assign(socket, @init_assigns)
      end

    {:ok, assign(socket, :user, session["user"])}
  end

  defp schedule_work(character_name, session, socket) do
  end

  # This character logs on
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
