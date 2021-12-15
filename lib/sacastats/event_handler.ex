defmodule SacaStats.EventHandler do
  use PS2.SocketClient
  require Logger

  import Ecto.Query

  alias SacaStats.Repo
  alias SacaStats.CharacterSession
  alias SacaStats.SessionTracker
  alias Phoenix.PubSub

  def start_link(subscriptions) do
    PS2.SocketClient.start_link(__MODULE__, subscriptions)
  end

  # ESS events
  def handle_event({_event, %{"character_id" => "0"}}), do: nil

  def handle_event(
        {"GainExperience",
         %{"character_id" => character_id, "amount" => xp_amount, "experience_id" => xp_id_str}}
      ) do
    with {:ok, %CharacterSession{xp_types: xp_types} = session} <-
           SessionTracker.get(character_id) do
      xp_id = String.to_integer(xp_id_str)
      xp = String.to_integer(xp_amount)

      CharacterSession.changeset(session, %{
        xp_earned: session.xp_earned + xp,
        xp_types: Map.update(xp_types, xp_id, xp, &(&1 + xp))
      })
      |> SessionTracker.update()
    end
  end

  def handle_event(
        {"Death",
         %{
           "character_id" => character_id,
           "attacker_character_id" => attacker_id,
           "attacker_weapon_id" => weapon_id_str,
           "attacker_vehicle_id" => vehicle_id_str,
           "is_headshot" => is_headshot
         }}
      ) do
    weapon = SacaStats.weapons()[String.to_integer(weapon_id_str)]

    # If the weapon is considered an IvI weapon and the attacker is not in a vehicle, ivi_kill = 1, else ivi_kill = 0
    ivi_kill =
      if weapon["sanction"] == "infantry" and vehicle_id_str == "0" do
        1
      else
        0
      end

    headshot_kill = String.to_integer(is_headshot)

    with {:ok, %CharacterSession{} = session} <- SessionTracker.get(character_id) do
      CharacterSession.changeset(session, %{
        deaths: session.deaths + 1,
        deaths_ivi: session.deaths_ivi + ivi_kill
      })
      |> SessionTracker.update()
    end

    with {:ok, %CharacterSession{} = session} <- SessionTracker.get(attacker_id) do
      CharacterSession.changeset(session, %{
        kills: session.kills + 1,
        kills_hs: session.kills_hs + headshot_kill,
        kills_ivi: session.kills_ivi + ivi_kill,
        kills_hs_ivi: session.kills_hs_ivi + Bitwise.&&&(ivi_kill, headshot_kill)
      })
      |> SessionTracker.update()
    end
  end

  def handle_event(
        {"PlayerLogin", %{"character_id" => character_id, "timestamp" => timestamp}}
      ) do
    SessionTracker.put(character_id, timestamp)
  end

  def handle_event(
        {"PlayerLogout", %{"character_id" => character_id, "timestamp" => timestamp}}
      ) do
    SessionTracker.close(character_id, timestamp)
  end

  def handle_event(
        {"VehicleDestroy",
         %{
           "character_id" => character_id,
           "vehicle_id" => vehicle_id_str,
           "attacker_character_id" => attacker_id
         }}
      ) do
    vehicle_id = String.to_integer(vehicle_id_str)

    with {:ok, vehicle} <- Map.fetch(SacaStats.vehicles(), vehicle_id) do
      with {:ok, %CharacterSession{vehicles_lost: vehicles_lost} = session} <-
             SessionTracker.get(character_id) do
        CharacterSession.changeset(session, %{
          vehicles_lost: Map.update(vehicles_lost, vehicle["name"], 1, &(&1 + 1)),
          nanites_lost: session.nanites_lost + vehicle["cost"],
          vehicle_deaths: session.vehicle_deaths + 1
        })
        |> SessionTracker.update()
      end

      with {:ok, %CharacterSession{vehicles_destroyed: vehicles_destroyed} = session}
           when attacker_id != character_id <- SessionTracker.get(attacker_id) do
        CharacterSession.changeset(session, %{
          vehicles_destroyed: Map.update(vehicles_destroyed, vehicle["name"], 1, &(&1 + 1)),
          nanites_destroyed: session.nanites_destroyed + vehicle["cost"],
          vehicle_kills: session.vehicle_kills + 1
        })
        |> SessionTracker.update()
      end
    end
  end

  def handle_event({"PlayerFacilityCapture", %{"character_id" => character_id}}) do
    with {:ok, %CharacterSession{} = session} <- SessionTracker.get(character_id) do
      CharacterSession.changeset(session, %{base_captures: session.base_captures + 1})
      |> SessionTracker.update()
    end
  end

  def handle_event({"PlayerFacilityDefend", %{"character_id" => character_id}}) do
    with {:ok, %CharacterSession{} = session} <- SessionTracker.get(character_id) do
      CharacterSession.changeset(session, %{base_defends: session.base_defends + 1})
      |> SessionTracker.update()
    end
  end

  def handle_event({"BattleRankUp", %{"character_id" => character_id, "battle_rank" => br}}) do
    with {:ok, %CharacterSession{} = session} <- SessionTracker.get(character_id) do
      CharacterSession.changeset(session, %{br_ups: [br | session.br_ups]})
      |> SessionTracker.update()
    end
  end

  # Metagame end
  def handle_event(
        {"MetagameEvent", %{"metagame_event_id" => event_id_str, "metagame_event_state" => "138"}}
      ) do
    event_id = String.to_integer(event_id_str)

    event = {:metagame_end, Map.get(SacaStats.events(), event_id), []}
    PubSub.broadcast(SacaStats.PubSub, "game_stats", event)
  end

  # Metagame start
  def handle_event(
        {"MetagameEvent", %{"metagame_event_id" => event_id_str, "metagame_event_state" => "135"}}
      ) do
    event_id = String.to_integer(event_id_str)

    query =
      from(s in "event_subscriptions",
        where: ^event_id in s.event_ids,
        select: s.user_id
      )

    user_ids = Repo.all(query)
    event = {:metagame_start, Map.get(SacaStats.events(), event_id), user_ids}
    PubSub.broadcast(SacaStats.PubSub, "game_status", event)
  end

  def handle_event({"ContinentLock", %{"world_id" => world_id_str, "zone_id" => zone_id_str}}) do
    world_id = String.to_integer(world_id_str)
    zone_id = String.to_integer(zone_id_str)

    event =
      {:lock, Map.get(SacaStats.worlds(), world_id), Map.get(SacaStats.zones(), zone_id), []}

    PubSub.broadcast(SacaStats.PubSub, "game_status", event)
  end

  def handle_event({"ContinentUnlock", %{"world_id" => world_id_str, "zone_id" => zone_id_str}}) do
    world_id = String.to_integer(world_id_str)
    zone_id = String.to_integer(zone_id_str)

    query =
      from(s in "unlock_subscriptions",
        where: ^world_id in s.world_ids and ^zone_id in s.zone_ids,
        select: s.user_id
      )

    user_ids = Repo.all(query)

    event =
      {:unlock, Map.get(SacaStats.worlds(), world_id), Map.get(SacaStats.zones(), zone_id),
       user_ids}

    PubSub.broadcast(SacaStats.PubSub, "game_status", event)
  end

  # Catch-all callback.
  def handle_event(_event), do: nil
end
