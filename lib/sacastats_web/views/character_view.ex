defmodule SacaStatsWeb.CharacterView do
  use SacaStatsWeb, :view

  alias SacaStats.{CensusCache, Events, Session}

  alias SacaStats.Events.{
    BattleRankUp,
    PlayerFacilityCapture,
    PlayerFacilityDefend,
    Death,
    VehicleDestroy
  }

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

    all_character_ids =
      Enum.reduce(events, MapSet.new(), fn
        %{character_id: id, attacker_character_id: a_id}, mapset ->
          mapset
          |> MapSet.put(id)
          |> MapSet.put(a_id)

        %{character_id: id}, mapset ->
          MapSet.put(mapset, id)
      end)

    {:ok, character_map} = CensusCache.get_many(SacaStats.CharacterCache, all_character_ids)

    ~H"""
    <ul>
      <%= for e <- events do %>
        <%= build_event_log_item(assigns, e, session, character_map) %>
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
    character_identifier = get_character_name(character_map, death.character_id)
    attacker_identifier = get_character_name(character_map, death.attacker_character_id)

    ~H"""
    <li>
      <%= attacker_identifier %> killed <%= character_identifier %>
      with <%= SacaStats.weapons()[death.attacker_weapon_id]["name"] %> (<%= death.attacker_weapon_id %>)
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
    character_identifier = get_character_name(character_map, vd.character_id)
    attacker_identifier = get_character_name(character_map, vd.attacker_character_id)

    ~H"""
    <li>
      <%= attacker_identifier %> destroyed <%= character_identifier %>'s <%= SacaStats.vehicles()[vd.vehicle_id]["name"] %>
      with <%= SacaStats.weapons()[vd.attacker_weapon_id]["name"] %> (<%= vd.attacker_weapon_id %>)
      <%= vd.attacker_vehicle_id != 0 && " while in a #{SacaStats.vehicles()[vd.attacker_vehicle_id]["name"]}" || "" %>
      -
      <%= SacaStatsWeb.CharacterView.prettify_timestamp(assigns, vd.timestamp) %>
    </li>
    """
  end

  defp get_character_name(character_map, character_id) do
    case character_map do
      %{^character_id => %{"name" => %{"first" => name}}} ->
        name

      _ ->
        "somebody (#{character_id})"
    end
  end
end
