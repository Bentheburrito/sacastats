defmodule SacaStatsWeb.CharacterView do
  use SacaStatsWeb, :view

  import SacaStats, only: [is_assist_xp: 1]

  alias SacaStats.Census.Character
  alias SacaStats.Session

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
    ~H"""
    <ul>
      <%= for e <- assigns.events do %>
        <%= build_event_log_item(assigns, e, session, assigns.character_map) %>
      <% end %>
    </ul>
    """
  end

  defp build_event_log_item(assigns, %BattleRankUp{} = br_up, %Session{} = session, _c_map) do
    ~H"""
    <li>
      <%= session.name %> ranked up to <%= br_up.battle_rank %> -
      <%= SacaStatsWeb.CharacterView.prettify_timestamp(assigns, br_up.timestamp) %>
    </li>
    """
  end

  defp build_event_log_item(assigns, %Death{} = death, %Session{}, character_map) do
    character_identifier = get_character_name(assigns, character_map, death.character_id)
    attacker_identifier = get_character_name(assigns, character_map, death.attacker_character_id)
    attacker_weapon_identifier = get_weapon_name(assigns, death.attacker_weapon_id)

    ~H"""
    <li>
      <%= attacker_identifier %> killed <%= character_identifier %>
      with <%= attacker_weapon_identifier %>
      <%= death.is_headshot && "(headshot)" || "" %>
      -
      <%= SacaStatsWeb.CharacterView.prettify_timestamp(assigns, death.timestamp) %>
    </li>
    """
  end

  defp build_event_log_item(assigns, %PlayerFacilityCapture{} = cap, %Session{} = session, _c_map) do
    ~H"""
    <li>
      <%= session.name %> captured <%= cap.facility_id %> (new outfit owner: <%= cap.outfit_id %>) -
      <%= SacaStatsWeb.CharacterView.prettify_timestamp(assigns, cap.timestamp) %>
    </li>
    """
  end

  defp build_event_log_item(assigns, %PlayerFacilityDefend{} = def, %Session{} = session, _) do
    ~H"""
    <li>
      <%= session.name %> defended <%= def.facility_id %> (outfit owner: <%= def.outfit_id %>) -
      <%= SacaStatsWeb.CharacterView.prettify_timestamp(assigns, def.timestamp) %>
    </li>
    """
  end

  defp build_event_log_item(assigns, %VehicleDestroy{} = vd, %Session{}, character_map) do
    character_identifier = get_character_name(assigns, character_map, vd.character_id)
    attacker_identifier = get_character_name(assigns, character_map, vd.attacker_character_id)
    attacker_weapon_identifier = get_weapon_name(assigns, vd.attacker_weapon_id)

    ~H"""
    <li>
      <%= attacker_identifier %> destroyed <%= character_identifier %>'s <%= SacaStats.vehicles()[vd.vehicle_id]["name"] %>
      with <%= attacker_weapon_identifier %>
      <%= vd.attacker_vehicle_id != 0 && " while in a #{SacaStats.vehicles()[vd.attacker_vehicle_id]["name"]}" || "" %>
      -
      <%= SacaStatsWeb.CharacterView.prettify_timestamp(assigns, vd.timestamp) %>
    </li>
    """
  end

  defp build_event_log_item(
         assigns,
         %GainExperience{experience_id: id, character_id: character_id} = ge,
         %Session{character_id: character_id},
         character_map
       )
       when is_assist_xp(id) do
    other_identifier = get_character_name(assigns, character_map, ge.other_id)
    character_identifier = get_character_name(assigns, character_map, character_id)

    ~H"""
    <li>
      <%= character_identifier %> assisted in killing <%= other_identifier %>
      -
      <%= SacaStatsWeb.CharacterView.prettify_timestamp(assigns, ge.timestamp) %>
    </li>
    """
  end

  defp build_event_log_item(assigns, %PlayerLogin{}, %Session{name: name}, _character_map) do
    ~H"""
    <%= name %> logged in.
    """
  end

  defp build_event_log_item(assigns, %PlayerLogout{}, %Session{name: name}, _character_map) do
    ~H"""
    <%= name %> logged out.
    """
  end

  defp build_event_log_item(_, _, _, _), do: ""

  defp get_character_name(assigns, _character_map, 0) do
    ~H"""
    [Unknown Character]
    """
  end

  defp get_character_name(assigns, character_map, character_id) do
    case character_map do
      %{^character_id => {:ok, %Character{name_first: name}}} ->
        ~H"""
        <a href={"/character/#{name}"}><%= name %></a>
        """

      _ ->
        ~H"""
        <a href={"/character/#{character_id}"}><%= character_id %></a> (Character Search Failed)
        """
    end
  end

  defp get_weapon_name(assigns, 0) do
    ~H"[Unknown Weapon]"
  end

  defp get_weapon_name(assigns, weapon_id) do
    ~H"""
    <%= SacaStats.weapons()[weapon_id]["name"] %> (<%= weapon_id %>)
    """
  end
end
