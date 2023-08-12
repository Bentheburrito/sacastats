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
    login_time = prettify_timestamp(session.login.timestamp)
    logout_time = prettify_timestamp(session.logout.timestamp)
    session_duration = prettify_duration(session.login.timestamp, session.logout.timestamp)

    ~H"""
    <div class="poll-item text-light">
      <%= login_time %> → <%= logout_time %>
      <br>
      <%= session_duration %>
    </div>
    """
  end

  def prettify_timestamp(:loading), do: "Loading..."
  def prettify_timestamp(nil), do: ""
  def prettify_timestamp(:current_session), do: "Current Session"

  def prettify_timestamp(timestamp) do
    dt_string =
      timestamp
      |> DateTime.from_unix!()
      |> to_string()

    id = :rand.uniform(999_999_999)

    assigns = []

    ~H"""
    <span class="date-time" id={"formatted-timestamp-#{id}"} phx-hook="NewDateToFormat"><%= dt_string %></span>
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
            weapon_name = get_weapon_name(death.attacker_weapon_id)
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

  def get_event_log_table_col_span_count(), do: 3

  def get_event_log_table_id(), do: "eventLogTable"

  def build_event_log(assigns, %Session{} = session) do
    ~H"""
      <table class="table table-bordered table-striped table-responsive-stack" id={"#{get_event_log_table_id()}"}
        data-sort-name="timestamp"
        data-sort-order="asc"
        data-sticky-header="true"
        data-sticky-header-offset-y="210"
        phx-hook="InitEventLogTable">
        <thead class="">
            <tr>
              <th data-field="killer" data-toggle="tooltip" title="Killer">Killer</th>
              <th data-field="method" data-switchable="false" data-toggle="tooltip" title="Method" class="weapon">Method</th>
              <th data-field="victum" data-visible="false" data-toggle="tooltip" title="Victum">Victum</th>
              <th data-field="timestamp" data-visible="false" data-toggle="tooltip" title="Timestamp">Timestamp</th>
              <th data-field="type" data-visible="false" data-toggle="tooltip" title="Type">Type</th>
            </tr>
        </thead>
        <tbody>
          <%= Logger.error("restarting..............................................................") %>
          <%= for e <- assigns.events do %>
            <%= build_event_log_table_row(assigns, e, session, assigns.character_map) %>
          <% end %>
        </tbody>
      </table>
    """
  end

  defp build_event_log_table_player_cell(character_link) do
    # need `assigns` map in scope to use ~H
    assigns = %{}

    ~H"""
      <td>
        <%= character_link %>
      </td>
    """
  end

  defp build_event_log_table_weapon_cell(weapon_id) do
    # need `assigns` map in scope to use ~H
    assigns = %{}

    ~H"""
      <td class="weapon p-0">
          <div class="weapon-image-container w-100">
              <img src={"https://census.daybreakgames.com" <> get_weapon_image_path(weapon_id)}
                  onerror={"this.onerror=null; this.src='" <>
                      (if is_vehicle_weapon(weapon_id),
                          do: "/images/character/unknownVehicleWeapon.png",
                          else: "/images/character/unknownInfantryWeapon.png")
                      <> "'"}
                  alt={get_weapon_name(weapon_id)} class="weapon-image mx-auto d-block"/>
          </div>
          <h5 class="weaponName align-text-bottom text-center mb-0"><%=get_weapon_name(weapon_id)%></h5>
      </td>
    """
  end

  defp build_event_log_table_row(assigns, %BattleRankUp{} = e, %Session{} = session, c_map) do
    build_event_log_table_row_items(assigns, e, session, c_map)
  end

  defp build_event_log_table_row(assigns, %Death{} = e, %Session{} = session, c_map) do
    build_event_log_table_row_items(assigns, e, session, c_map)
  end

  defp build_event_log_table_row(assigns, %PlayerFacilityCapture{} = e, %Session{} = session, c_map) do
    build_event_log_table_row_items(assigns, e, session, c_map)
  end

  defp build_event_log_table_row(assigns, %PlayerFacilityDefend{} = e, %Session{} = session, c_map) do
    build_event_log_table_row_items(assigns, e, session, c_map)
  end

  defp build_event_log_table_row(assigns, %VehicleDestroy{} = e, %Session{} = session, c_map) do
    build_event_log_table_row_items(assigns, e, session, c_map)
  end

  defp build_event_log_table_row(assigns, %GainExperience{experience_id: id, other_id: _other_id} = e, %Session{} = session, c_map)
      when is_assist_xp(id) or is_gunner_assist_xp(id) or is_revive_xp(id) do
    build_event_log_table_row_items(assigns, e, session, c_map)
  end

  defp build_event_log_table_row(assigns, %GainExperience{experience_id: id, character_id: _character_id} = e, %Session{} = session, c_map)
      when is_assist_xp(id) or is_gunner_assist_xp(id) or is_revive_xp(id) do
    build_event_log_table_row_items(assigns, e, session, c_map)
  end

  defp build_event_log_table_row(assigns, %PlayerLogin{} = e, %Session{} = session, c_map) do
    build_event_log_table_row_items(assigns, e, session, c_map)
  end

  defp build_event_log_table_row(assigns, %PlayerLogout{} = e, %Session{} = session, c_map) do
    build_event_log_table_row_items(assigns, e, session, c_map)
  end

  defp build_event_log_table_row(assigns, _e, _session, _c_map) do
    ~H"""
    """
  end

  defp build_event_log_table_row_items(assigns, e, %Session{} = session, c_map) do
    ~H"""
      <tr id={"eventLogTable#{e.timestamp}Row"}>
        <%= build_event_log_table_row_item(assigns, e, session, c_map) %>
        <td>
          <%= SacaStatsWeb.CharacterView.prettify_timestamp(e.timestamp) %>
        </td>
        <td>
          <%= Logger.error(e) %>
        </td>
      </tr>
    """
  end

  defp build_event_log_table_row_item(assigns, %BattleRankUp{} = br_up, %Session{} = session, _c_map) do
    ~H"""
      <td colspan={"#{get_event_log_table_col_span_count()}"}>
        <%= format_faction_character_link(session.name, session.faction_id) %> ranked up to <%= br_up.battle_rank %>
      </td>
    """
  end

  # Suicide
  defp build_event_log_table_row_item(
         assigns,
         %Death{character_id: character_id, attacker_character_id: character_id} = death,
         %Session{},
         character_map
       ) do
    character_link = get_character_name(character_map, character_id)

    ~H"""
      <td>

      </td>
      <%= build_event_log_table_weapon_cell(death.attacker_weapon_id) %>
      <%= build_event_log_table_player_cell(character_link) %>
    """
  end

  defp build_event_log_table_row_item(assigns, %Death{} = death, %Session{}, character_map) do
    character_link = get_character_name(character_map, death.character_id)
    attacker_link = get_character_name(character_map, death.attacker_character_id)

    ~H"""
      <%= build_event_log_table_player_cell(attacker_link) %>
      <%= build_event_log_table_weapon_cell(death.attacker_weapon_id) %>
      <%= build_event_log_table_player_cell(character_link) %>
    """
  end

  defp build_event_log_table_row_item(assigns, %PlayerFacilityCapture{} = cap, %Session{} = session, _c_map) do
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
    <td colspan={"#{get_event_log_table_col_span_count()}"}>
      <%= format_character_link(session.name, session.faction_id) %> captured
      <%= "#{facility["facility_name"] || "a facility"} #{facility_type_text}" %>
      <%= outfit_captured_text %>
    </td>
    """
  end

  defp build_event_log_table_row_item(assigns, %PlayerFacilityDefend{} = def, %Session{} = session, _) do
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
    <td colspan={"#{get_event_log_table_col_span_count()}"}>
      <%= format_character_link(session.name, session.faction_id) %> defended
      <%= "#{facility["facility_name"] || "a facility"} #{facility_type_text}" %>
      <%= outfit_captured_text %>
    </td>
    """
  end

  # Destroyed own vehicle
  defp build_event_log_table_row_item(
         assigns,
         %VehicleDestroy{character_id: character_id, attacker_character_id: character_id} = vd,
         %Session{},
         character_map
       ) do
    character_link = get_character_name(character_map, character_id)

    ~H"""
      <%= build_event_log_table_player_cell(character_link) %>
      <%= build_event_log_table_weapon_cell(vd.attacker_weapon_id) %>
      <td>
        Their <%= SacaStats.vehicles()[vd.vehicle_id]["name"] %>
      </td>
    """
  end

  defp build_event_log_table_row_item(assigns, %VehicleDestroy{} = vd, %Session{}, character_map) do
    character_link = get_character_name(character_map, vd.character_id)
    attacker_link = get_character_name(character_map, vd.attacker_character_id)

    ~H"""
      <%= build_event_log_table_player_cell(attacker_link) %>
      <%= build_event_log_table_weapon_cell(vd.attacker_weapon_id) %>
      <%= build_event_log_table_player_cell(character_link) %>
    """
  end

  # Kill assist
  defp build_event_log_table_row_item(
         assigns,
         %GainExperience{experience_id: id, character_id: character_id} = ge,
         %Session{character_id: character_id},
         character_map
       )
       when is_assist_xp(id) do
    other_link = get_character_name(character_map, ge.other_id)
    character_link = get_character_name(character_map, character_id)

    ~H"""
      <%= build_event_log_table_player_cell(character_link) %>
      <td>
        assisted in killing
      </td>
      <%= build_event_log_table_player_cell(other_link) %>
    """
  end

  # Got revived by someone
  defp build_event_log_table_row_item(
         assigns,
         %GainExperience{experience_id: id, other_id: character_id} = ge,
         %Session{character_id: character_id},
         character_map
       )
       when is_revive_xp(id) do
    other_identifier = get_character_name(character_map, ge.character_id)
    character_identifier = get_character_name(character_map, character_id)

    ~H"""
    <td colspan={"#{get_event_log_table_col_span_count()}"}>
      <%= other_identifier %> revived <%= character_identifier %>
    </td>
    """
  end

  # Revived someone
  defp build_event_log_table_row_item(
         assigns,
         %GainExperience{experience_id: id, character_id: character_id} = ge,
         %Session{character_id: character_id},
         character_map
       )
       when is_revive_xp(id) do
    other_identifier = get_character_name(character_map, ge.other_id)
    character_identifier = get_character_name(character_map, character_id)

    ~H"""
    <td colspan={"#{get_event_log_table_col_span_count()}"}>
      <%= character_identifier %> revived <%= other_identifier %>
    </td>
    """
  end

  # Gunner gets a kill
  defp build_event_log_table_row_item(
         assigns,
         %GainExperience{experience_id: id, character_id: character_id} = ge,
         %Session{character_id: character_id},
         character_map
       )
       when is_gunner_assist_xp(id) do
    other_identifier = get_character_name(character_map, ge.other_id)
    character_identifier = get_character_name(character_map, character_id)

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
    <td colspan={"#{get_event_log_table_col_span_count()}"}>
      <%= event_log_message %>
    </td>
    """
  end

  defp build_event_log_table_row_item(assigns, %PlayerLogin{}, %Session{name: name, faction_id: faction_id}, _character_map) do
    ~H"""
    <td colspan={"#{get_event_log_table_col_span_count()}"}><%= format_character_link(name, faction_id) %> logged in.</td>
    """
  end

  defp build_event_log_table_row_item(assigns, %PlayerLogout{}, %Session{name: name, faction_id: faction_id}, _character_map) do
    ~H"""
    <td colspan={"#{get_event_log_table_col_span_count()}"}><%= format_character_link(name, faction_id) %> logged out.</td>
    """
  end

  defp build_event_log_table_row_item(_, _, _, _), do: ""

  defp get_character_name(_character_map, 0), do: "[Unknown Character]"

  defp get_character_name(character_map, character_id) do
    case character_map do
      %{^character_id => {:ok, %Character{name_first: name, faction_id: faction_id}}} ->
        format_faction_character_link(name, faction_id)

      _ ->
        format_faction_character_link(character_id, 0, " (Character Search Failed)")
    end
  end

  defp format_faction_character_link(identifier, faction_id, note \\ "") do
    # need `assigns` map in scope to use ~H
    assigns = %{}
    faction_alias = Map.get(SacaStats.factions(), faction_id)[:alias]

    ~H"""
    <a class={"#{faction_alias}-link"} href={"/character/#{identifier}"}><%= identifier %></a><%= note %>
    """
  end

  defp format_character_link(identifier, faction_id, note \\ "") do
    # need `assigns` map in scope to use ~H
    assigns = %{}

    ~H"""
    <a href={"/character/#{identifier}"}><%= identifier %></a><%= note %>
    """
  end

  defp get_weapon_name(0), do: "[Unknown Weapon]"

  defp get_weapon_name(weapon_id), do: SacaStats.weapons()[weapon_id]["name"]

  defp get_weapon_image_path(0), do: "/files/ps2/images/static/-1.png"

  defp get_weapon_image_path(weapon_id) do
    weapon = SacaStats.weapons()[weapon_id]
    case weapon do
      nil -> "/files/ps2/images/static/-1.png"
      _ -> weapon["image_path"]
    end
  end

  defp is_vehicle_weapon(0), do: false

  defp is_vehicle_weapon(weapon_id), do: SacaStats.weapons()[weapon_id]["vehicle_weapon?"]
end
