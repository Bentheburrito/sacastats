defmodule SacaStatsWeb.CharacterView do
  use SacaStatsWeb, :view

  alias SacaStats.{Events, Session}

  require Logger

  def next_battle_rank(character_info) do
    character_info
    |> get_in(["battle_rank", "value"])
    |> String.to_integer()
    |> Kernel.+(1)
  end

  def pretty_session_summary(assigns, session) do
    login_time = prettify_timestamp(assigns, session.login.timestamp)
    logout_time = prettify_timestamp(assigns, session.logout.timestamp)
    session_duration = prettify_duration(session.login.timestamp, session.logout.timestamp)

    ~H"""
    <div class="poll-item text-dark">
      <%= login_time %> → <%= logout_time %>
      <br>
      <%= session_duration %>
    </div>
    """
  end

  def prettify_timestamp(_assigns, :current_session), do: "Current Session"

  def prettify_timestamp(assigns, timestamp) do
    dt_string =
      timestamp
      |> DateTime.from_unix!()
      |> to_string()
      |> String.trim_trailing("Z")

    ~H"""
    <span class="date-time"><%= dt_string %></span>
    """
  end

  def prettify_duration(start_ts, :current_session),
    do: prettify_duration(start_ts, System.os_time(:second))

  def prettify_duration(start_ts, end_ts) do
    total_seconds = end_ts - start_ts
    seconds = rem(total_seconds, 60)
    minutes = rem(div(total_seconds, 60), 60)
    hours = rem(div(total_seconds, 60 * 60), 60)

    [{hours, "hours"}, {minutes, "minutes"}, {seconds, "seconds"}]
    |> Stream.filter(fn {duration, _unit} -> duration > 0 end)
    |> Stream.map(fn {duration, unit} -> "#{duration} #{unit}" end)
    |> Enum.join(" ")
  end

  def build_event_log(assigns, %Session{} = session) do
    events =
      (session.battle_rank_ups ++
         session.player_facility_captures ++
         session.player_facility_defends ++
         session.vehicle_destroys ++
         session.deaths)
      |> Enum.sort_by(fn event -> event.timestamp end, :desc)

    ~H"""
    <ul>
      <%= for e <- events do %>
        <%= build_event_log_item(assigns, e, session) %>
      <% end %>
    </ul>
    """
  end

  defp build_event_log_item(assigns, %Events.BattleRankUp{} = br_up, %Session{} = session) do
    ~H"""
    <li>
      <%= session.name %> ranked up to <%= br_up.battle_rank %> -
      <%= SacaStatsWeb.CharacterView.prettify_timestamp(assigns, br_up.timestamp) %>
    </li>
    """
  end

  defp build_event_log_item(assigns, %Events.Death{} = death, %Session{} = _session) do
    ~H"""
    <li>
      <%= death.attacker_character_id %> killed <%= death.character_id %>
      with <%= SacaStats.weapons()[death.attacker_weapon_id]["name"] %> (<%= death.attacker_weapon_id %>)
      <%= death.is_headshot && "(headshot)" || "" %>
      -
      <%= SacaStatsWeb.CharacterView.prettify_timestamp(assigns, death.timestamp) %>
    </li>
    """
  end

  defp build_event_log_item(assigns, %Events.PlayerFacilityCapture{} = cap, %Session{} = session) do
    ~H"""
    <li>
      <%= session.name %> captured <%= cap.facility_id %> (new outfit owner: <%= cap.outfit_id %>) -
      <%= SacaStatsWeb.CharacterView.prettify_timestamp(assigns, cap.timestamp) %>
    </li>
    """
  end

  defp build_event_log_item(assigns, %Events.PlayerFacilityDefend{} = def, %Session{} = session) do
    ~H"""
    <li>
      <%= session.name %> defended <%= def.facility_id %> (outfit owner: <%= def.outfit_id %>) -
      <%= SacaStatsWeb.CharacterView.prettify_timestamp(assigns, def.timestamp) %>
    </li>
    """
  end

  defp build_event_log_item(assigns, %Events.VehicleDestroy{} = vd, %Session{} = session) do
    ~H"""
    <li>
      <%= vd.attacker_character_id %> destroyed <%= vd.character_id %>'s <%= SacaStats.vehicles()[vd.vehicle_id]["name"] %>
      with <%= SacaStats.weapons()[vd.attacker_weapon_id]["name"] %> (<%= vd.attacker_weapon_id %>)
      <%= vd.attacker_vehicle_id != 0 && " while in a #{SacaStats.vehicles()[vd.attacker_vehicle_id]["name"]}" || "" %>
      -
      <%= SacaStatsWeb.CharacterView.prettify_timestamp(assigns, vd.timestamp) %>
    </li>
    """
  end
end
