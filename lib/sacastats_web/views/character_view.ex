defmodule SacaStatsWeb.CharacterView do
  use SacaStatsWeb, :view

  import SacaStats, only: [is_assist_xp: 1, is_gunner_assist_xp: 1, is_revive_xp: 1]

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

  def build_kills_by_weapon(assigns, %Session{} = session) do
    weapon_kill_counts =
      for %Death{} = death <- session.deaths,
          death.attacker_character_id == session.character_id,
          reduce: %{} do
        weapon_kill_counts ->
          if is_nil(SacaStats.weapons()[death.attacker_weapon_id]) do
            weapon_kill_counts
          else
            weapon_name = get_weapon_name(assigns, death.attacker_weapon_id)
            Map.update(weapon_kill_counts, weapon_name, 1, &(&1 + 1))
          end
      end

    ~H"""
    <ul>
      <%= for {weapon_name, kill_count} <- Enum.sort_by(weapon_kill_counts, &-elem(&1, 1)) do %>
        <li><%= kill_count %>x <%= weapon_name %></li>
      <% end %>
    </ul>
    """
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
      <%= format_character_link(session.name) %> ranked up to <%= br_up.battle_rank %> -
      <%= SacaStatsWeb.CharacterView.prettify_timestamp(assigns, br_up.timestamp) %>
    </li>
    """
  end

  # Suicide
  defp build_event_log_item(
         assigns,
         %Death{character_id: character_id, attacker_character_id: character_id} = death,
         %Session{},
         character_map
       ) do
    character_identifier = get_character_name(assigns, character_map, character_id)
    weapon_identifier = get_weapon_name(assigns, death.attacker_weapon_id)

    ~H"""
    <li>
      <%= character_identifier %> seems to have killed themself with <%= weapon_identifier %>
      -
      <%= SacaStatsWeb.CharacterView.prettify_timestamp(assigns, death.timestamp) %>
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
    facility = SacaStats.facilities()[cap.facility_id]

    facility_type_text =
      if facility["facility_type"] in ["Small Outpost", "Large Outpost"] do
        ""
      else
        facility["facility_type"]
      end

    # can't do this right now, need outfit ID from FacilityControl events (the one provided here is just the player's
    # current outfit :/)
    outfit_captured_text = ""
    # if cap.outfit_id == session.outfit.outfit_id do
    #   "for #{session.outfit.name}!"
    # else
    #   ""
    # end

    ~H"""
    <li>
      <%= format_character_link(session.name) %> captured
      <%= "#{facility["facility_name"] || "a facility"} #{facility_type_text}" %>
      <%= outfit_captured_text %> -
      <%= SacaStatsWeb.CharacterView.prettify_timestamp(assigns, cap.timestamp) %>
    </li>
    """
  end

  defp build_event_log_item(assigns, %PlayerFacilityDefend{} = def, %Session{} = session, _) do
    facility = SacaStats.facilities()[def.facility_id]

    facility_type_text =
      if facility["facility_type"] in ["Small Outpost", "Large Outpost"] do
        ""
      else
        facility["facility_type"]
      end

    outfit_captured_text = ""
    # if def.outfit_id == session.outfit.outfit_id do
    #   "for #{session.outfit.name}!"
    # else
    #   ""
    # end

    ~H"""
    <li>
      <%= format_character_link(session.name) %> defended
      <%= "#{facility["facility_name"] || "a facility"} #{facility_type_text}" %>
      <%= outfit_captured_text %> -
      <%= SacaStatsWeb.CharacterView.prettify_timestamp(assigns, def.timestamp) %>
    </li>
    """
  end

  # Destroyed own vehicle
  defp build_event_log_item(
         assigns,
         %VehicleDestroy{character_id: character_id, attacker_character_id: character_id} = vd,
         %Session{},
         character_map
       ) do
    character_identifier = get_character_name(assigns, character_map, character_id)
    attacker_weapon_identifier = get_weapon_name(assigns, vd.attacker_weapon_id)

    ~H"""
    <li>
      <%= character_identifier %> destroyed their <%= SacaStats.vehicles()[vd.vehicle_id]["name"] %>
      with <%= attacker_weapon_identifier %>
      -
      <%= SacaStatsWeb.CharacterView.prettify_timestamp(assigns, vd.timestamp) %>
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

  # Kill assist
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

  # Got revived by someone
  defp build_event_log_item(
         assigns,
         %GainExperience{experience_id: id, other_id: character_id} = ge,
         %Session{character_id: character_id},
         character_map
       )
       when is_revive_xp(id) do
    other_identifier = get_character_name(assigns, character_map, ge.character_id)
    character_identifier = get_character_name(assigns, character_map, character_id)

    ~H"""
    <li>
      <%= other_identifier %> revived <%= character_identifier %>
      -
      <%= SacaStatsWeb.CharacterView.prettify_timestamp(assigns, ge.timestamp) %>
    </li>
    """
  end

  # Revived someone
  defp build_event_log_item(
         assigns,
         %GainExperience{experience_id: id, character_id: character_id} = ge,
         %Session{character_id: character_id},
         character_map
       )
       when is_revive_xp(id) do
    other_identifier = get_character_name(assigns, character_map, ge.other_id)
    character_identifier = get_character_name(assigns, character_map, character_id)

    ~H"""
    <li>
      <%= character_identifier %> revived <%= other_identifier %>
      -
      <%= SacaStatsWeb.CharacterView.prettify_timestamp(assigns, ge.timestamp) %>
    </li>
    """
  end

  # Gunner gets a kill
  defp build_event_log_item(
         assigns,
         %GainExperience{experience_id: id, character_id: character_id} = ge,
         %Session{character_id: character_id},
         character_map
       )
       when is_gunner_assist_xp(id) do
    other_identifier = get_character_name(assigns, character_map, ge.other_id)
    character_identifier = get_character_name(assigns, character_map, character_id)

    %{"description" => desc} = SacaStats.xp()[id]
    desc_downcase = String.downcase(desc)
    # {VehicleKilled} kill by {VehicleKiller} gunner{?}
    event_log_message =
      case String.split(desc_downcase, " kill by ") do
        ["player", vehicle_killer_gunner] ->
          vehicle_killer = String.trim_trailing(vehicle_killer_gunner, "gunner")

          ~H"<%= character_identifier %>'s <%= vehicle_killer %> gunner killed <%= other_identifier %>"

        [vehicle_killed, vehicle_killer_gunner] ->
          vehicle_killer = String.trim_trailing(vehicle_killer_gunner, "gunner")

          ~H"<%= character_identifier %>'s <%= vehicle_killer %> gunner destroyed a <%= vehicle_killed %>"

        _ ->
          Logger.warning(
            "Could not parse gunner assist xp for event log message: #{inspect(desc)}"
          )

          ~H"<%= desc %>"
      end

    ~H"""
    <li>
      <%= event_log_message %>
      -
      <%= SacaStatsWeb.CharacterView.prettify_timestamp(assigns, ge.timestamp) %>
    </li>
    """
  end

  defp build_event_log_item(assigns, %PlayerLogin{}, %Session{name: name}, _character_map) do
    ~H"""
    <li><%= format_character_link(name) %> logged in.</li>
    """
  end

  defp build_event_log_item(assigns, %PlayerLogout{}, %Session{name: name}, _character_map) do
    ~H"""
    <li><%= format_character_link(name) %> logged out.</li>
    """
  end

  defp build_event_log_item(_, _, _, _), do: ""

  defp get_character_name(assigns, _character_map, 0) do
    ~H"""
    [Unknown Character]
    """
  end

  defp get_character_name(_assigns, character_map, character_id) do
    case character_map do
      %{^character_id => {:ok, %Character{name_first: name}}} ->
        format_character_link(name)

      _ ->
        format_character_link(character_id, " (Character Search Failed)")
    end
  end

  defp format_character_link(identifier, note \\ "") do
    # need `assigns` map in scope to use ~H
    assigns = %{}

    ~H"""
    <a href={"/character/#{identifier}"}><%= identifier %></a><%= note %>
    """
  end

  defp get_weapon_name(assigns, 0) do
    ~H"[Unknown Weapon]"
  end

  defp get_weapon_name(assigns, weapon_id) do
    ~H"""
    <%= SacaStats.weapons()[weapon_id]["name"] %>
    """
  end
end
