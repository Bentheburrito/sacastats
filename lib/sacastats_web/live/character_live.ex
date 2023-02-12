defmodule SacaStatsWeb.CharacterLive do
  @moduledoc """
  LiveView for a character.
  """
  use SacaStatsWeb, :live_view

  require Logger

  import Ecto.Query

  alias SacaStatsWeb.CharacterLive
  alias Phoenix.PubSub
  alias SacaStats.Character.Favorite
  alias SacaStats.{Characters, Weapons}
  alias SacaStats.Census.{Character, OnlineStatus}
  alias SacaStats.Census.Character.Outfit
  alias SacaStats.Events.{PlayerLogin, PlayerLogout}
  alias SacaStats.Repo

  def init_assigns do
    %{
      character_info: %Character{
        head_id: 0,
        profile_type_description: "Light Assault",
        battle_rank: :loading,
        available_points: :loading
      },
      online_status: "loading",
      favorited?: :loading,
      inner_options: :loading
    }
  end

  def handle_params(%{"character_name" => character_name} = params, uri, socket) do
    IO.inspect(uri, label: "uri")
    IO.inspect(params, label: "params")
    IO.inspect(socket.assigns.live_action, label: "live action")

    # Begin getting the actual (possibly expensive) page data, receiving the result as a message later
    live_action = socket.assigns.live_action
    me = self()

    if connected?(socket) do
      Task.start_link(fn ->
        send_inner_assigns(me, live_action, socket.assigns.character_info)
      end)
    end

    {:noreply, assign(socket, request_path: URI.parse(uri).path, character_name: character_name)}
  end

  def mount(%{"character_name" => name}, session, socket) do
    socket =
      if connected?(socket) do
        user = session["user"]

        # Subscribe to favorite events if user is logged in
        if not is_nil(user) do
          PubSub.subscribe(SacaStats.PubSub, "favorite_event:#{user.id}")
          PubSub.subscribe(SacaStats.PubSub, "unfavorite_event:#{user.id}")
        end

        # Fetch expensive data (character_info, online_status, etc.)
        build_assigns(name, session, socket)
      else
        # Put default/loading assign data for init static load
        assign(socket, init_assigns())
      end

    # For both mounts, assign the user from the session
    {:ok, assign(socket, :user, session["user"])}
  end

  defp build_assigns(character_name, session, socket) do
    with {:ok, %Character{} = char} <- Characters.get_by_name(character_name) do
      # Start tasks to do some work concurrently
      online_status_task = Task.async(fn -> OnlineStatus.get_by_id(char.character_id) end)

      favorited_task =
        Task.async(fn ->
          if is_nil(session["user"]) do
            false
          else
            Characters.favorite?(char.character_id, session["user"].id)
          end
        end)

      # Subscribe to events from this character
      PubSub.subscribe(SacaStats.PubSub, "game_event:#{char.character_id}")

      # Get additional character info
      ethnicity = Characters.get_ethnicity(char.faction_id, char.head_id)
      sex = Characters.get_sex(char.faction_id, char.head_id)

      characteristics = %{
        "ethnicity" => ethnicity,
        "sex" => sex
      }

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
        characteristics: characteristics,
        favorited?: favorited?,
        inner_options: :loading
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

  defp send_inner_assigns(me, :general, %Character{} = char) do
    outfit_leader_name =
      with %Outfit{leader_character_id: leader_char_id} <- char.outfit,
           {:ok, %Character{name_first: name}} <- Characters.get_by_id(leader_char_id) do
        name
      else
        _ -> "Unknown Outfit Leader Name (ID #{char.outfit.leader_character_id})"
      end

    # Compile weapon stats
    compiled_stats = Weapons.compile_stats(char.weapon_stat, char.weapon_stat_by_faction)
    all_medal_counts = Weapons.medal_counts(compiled_stats)
    best_weapons = Weapons.compile_best_stats(compiled_stats)

    assigns = %{
      outfit_leader_name: outfit_leader_name,
      all_medal_counts: all_medal_counts,
      best_weapons: best_weapons
    }

    send(me, {:render_inner, "general.html", assigns})
    :ok
  end

  defp send_inner_assigns(me, :weapons, %Character{} = char) do
    assigns = %{}

    send(me, {:render_inner, "weapons.html", assigns})
    :ok
  end

  # if this character's favorited status is still loading, ignore when the user presses the button
  def handle_event("handle_favorite", %{"action" => "loading"}, socket), do: {:noreply, socket}

  def handle_event("handle_favorite", params, socket) do
    user_id = params |> Map.fetch!("user_id") |> String.to_integer()
    character_id = params |> Map.fetch!("character_id") |> String.to_integer()
    character_name = Map.fetch!(params, "character_name")
    action = Map.fetch!(params, "favorite_action")

    changeset =
      Favorite.changeset(%Favorite{}, %{
        :discord_id => user_id,
        :character_id => character_id,
        :last_known_name => character_name
      })

    action_result =
      if action == "favorite" do
        Repo.insert(changeset)
      else
        from(f in Favorite, where: f.discord_id == ^user_id and f.character_id == ^character_id)
        |> Repo.delete_all()
      end

    case action_result do
      {1, nil} ->
        PubSub.broadcast(
          SacaStats.PubSub,
          "unfavorite_event:#{user_id}",
          {:unfavorite, Ecto.Changeset.apply_changes(changeset)}
        )

        # NOTE: we don't update the `favorited?` assign here, because we subscribe to this user's favorites on mount,
        # so the LV will receive a message that updates the assigns for us (which is what the broadcast above does).
        {:noreply, socket}

      {0, nil} ->
        {:noreply,
         put_flash(socket, :info, "It looks like this character is already unfavorited.")}

      {:ok, favorite} ->
        PubSub.broadcast(
          SacaStats.PubSub,
          "favorite_event:#{favorite.discord_id}",
          {:favorite, favorite}
        )

        # See NOTE above
        {:noreply, socket}

      # This clause will only ever match when inserting
      {:error, changeset} ->
        Logger.error("Couldn't insert favorite character. Changeset: #{inspect(changeset)}")

        {:noreply,
         put_flash(
           socket,
           :error,
           "An error occured while adding #{character_name} to your favorites. Please try again"
         )}
    end
  end

  # This character logs on
  def handle_info(%Ecto.Changeset{data: %PlayerLogin{}}, socket) do
    {:noreply,
     assign(
       socket,
       :online_status,
       "online"
     )}
  end

  # This character logs off
  def handle_info(%Ecto.Changeset{data: %PlayerLogout{}}, socket) do
    {:noreply,
     assign(
       socket,
       :online_status,
       "offline"
     )}
  end

  # Catch-all for other kinds of player events
  def handle_info(%Ecto.Changeset{}, socket) do
    {:noreply, socket}
  end

  # The user favorites this character here or in another window
  def handle_info({:favorite, %Favorite{}}, socket) do
    {:noreply, assign(socket, favorited?: not socket.assigns.favorited?)}
  end

  # The user unfavorites this character here or in another window
  def handle_info({:unfavorite, %Favorite{}}, socket) do
    {:noreply, assign(socket, favorited?: not socket.assigns.favorited?)}
  end

  # New data arrives from a Task
  def handle_info({:render_inner, template_name, inner_assigns}, socket) do
    # the inner content will need access to things like :character_info, so merge them
    assigns = inner_assigns |> Map.merge(socket.assigns) |> Map.put(:socket, socket)

    {:noreply, assign(socket, :inner_options, {template_name, assigns})}
  end
end
