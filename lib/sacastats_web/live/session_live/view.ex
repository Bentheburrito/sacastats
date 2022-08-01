defmodule SacaStatsWeb.SessionLive.View do
  @moduledoc """
  LiveView for viewing character sessions.
  """
  use SacaStatsWeb, :live_view
  use Phoenix.HTML

	alias Phoenix.PubSub
  alias SacaStats.{CensusCache, Session}
	alias SacaStats.Events.{
		BattleRankUp,
		Death,
		GainExperience,
		PlayerFacilityCapture,
		PlayerFacilityDefend,
		PlayerLogin,
		PlayerLogout,
		VehicleDestroy
	}

  require Logger

	@module_to_field_name_map %{
		BattleRankUp => :battle_rank_ups,
		Death => :deaths,
		GainExperience => :gain_experiences,
		PlayerFacilityCapture => :player_facility_captures,
		PlayerFacilityDefend => :player_facility_defends,
		PlayerLogin => :player_logins,
		PlayerLogout => :player_logouts,
		VehicleDestroy => :vehicle_destroys,
	}

  def render(assigns) do
    Phoenix.View.render(SacaStatsWeb.CharacterView, "session.html", assigns)
  end

	def mount(%{"character_name" => name, "login_timestamp" => login_timestamp}, _user_session, socket) do
    %Session{} = session = Session.get(name, login_timestamp)
    {:ok, status} = CensusCache.get(SacaStats.OnlineStatusCache, session.character_id)

		PubSub.subscribe(SacaStats.PubSub, "game_event:#{to_string(session.character_id)}")

    socket =
			socket
      |> assign(:character_info, %{
        "character_id" => session.character_id,
        "name" => %{"first" => session.name},
        "faction_id" => session.faction_id,
        "outfit" => session.outfit
      })
      |> assign(:online_status, status)
      |> assign(:stat_page, "session.html")
      |> assign(:session, session)

    {:ok, socket}
  end

	def handle_info(%Ecto.Changeset{} = event_cs, socket) do
		%event_module{} = event = Ecto.Changeset.apply_changes(event_cs)
		field_name = Map.fetch!(@module_to_field_name_map, event_module)
		session = Map.update!(socket.assigns.session, field_name, &([event | &1]))

		{:noreply, assign(socket, :session, session)}
	end
end
