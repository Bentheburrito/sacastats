defmodule SacaStats do
  @moduledoc """
  SacaStats API for interacting with the census and data collected via ESS.
  """

  import Ecto.Query

  alias SacaStats.CharacterSession
  alias SacaStats.SessionTracker
  alias SacaStats.Utils.StaticData

  @zone_instance_bitmask 0x0000FFFF
  @static_data_path "./lib/sacastats/static_data"

  @type session_status :: :active | :closed | :both

  def sid(), do: System.get_env("SERVICE_ID")

  @spec get_sessions(session_status(), limit :: integer(), field :: atom(), field_value :: any()) :: [CharacterSession.t()]
  def get_sessions(session_status \\ :both, limit \\ 1, field \\ :character_id, field_value)

  def get_sessions(:closed, limit, field, field_value) do
    SacaStats.Repo.all(
      from(s in CharacterSession, select: s, where: field(s, ^field) == ^field_value, limit: ^limit)
    )
  end

  def get_sessions(:active, _limit, :character_id, character_id) do
    case SessionTracker.get(character_id) do
      {:ok, session} -> [session]
      :error -> []
    end
  end

  def get_sessions(:active, limit, field, field_value) when is_map_key(%CharacterSession{}, field) do
    SessionTracker.find(limit, fn %CharacterSession{} = session ->
      Map.get(session, field) == field_value
    end)
  end

  def get_sessions(:both, limit, field, field_value) do
    get_sessions(:active, limit, field, field_value) ++ get_sessions(:closed, limit, field, field_value)
  end

  @doc """
  Extracts the zone_id from a compound instance-zone id (as retrieved from ESS) using bitwise.
  """
  def extract_zone_id(zone_instance_id_str) when is_binary(zone_instance_id_str) do
    extract_zone_id(String.to_integer(zone_instance_id_str))
  end

  def extract_zone_id(zone_instance_id) do
    Bitwise.&&&(zone_instance_id, @zone_instance_bitmask)
  end

  @vehicles StaticData.load_static_file(@static_data_path <> "/vehicles.json")
  def vehicles, do: @vehicles

  @xp StaticData.load_static_file(@static_data_path <> "/xp.json")
  def xp, do: @xp

  @events StaticData.load_static_file(@static_data_path <> "/events.json")
  def events, do: @events

  @weapons StaticData.load_static_file(@static_data_path <> "/weapons.json")
  def weapons, do: @weapons

  def zones, do: %{
    2 => "Indar",
    4 => "Hossin",
    6 => "Amerish",
    8 => "Esamir",
    14 =>	"Koltyr",
    96 =>	"VR Training (NC)",
    97 =>	"VR Training (TR)",
    98 =>	"VR Training (VS)",
    361 => "Desolation",
    362 => "Sanctuary",
    364 => "Tutorial",
  }

  def worlds, do: %{
    1 => "Connery",
    10 => "Miller",
    13 => "Cobalt",
    17 => "Emerald",
    19 => "Jaeger",
    40 => "Soltech"
  }

  def factions, do: %{
    0 => {"No Faction", 0x575757, "https://i.imgur.com/9nHbnUh.jpg"},
    1 => {"Vanu Sovereignty", 0xB035F2, "https://bit.ly/2RCsHXs"},
    2 => {"New Conglomerate", 0x2A94F7, "https://bit.ly/2AOZJJB"},
    3 => {"Terran Republic", 0xE52D2D, "https://bit.ly/2Mm6wij"},
    4 => {"Nanite Systems", 0xE5E5E5, "https://i.imgur.com/9nHbnUh.jpg"}
  }

  def ess_subscriptions() do
    [
      events: [
        PS2.gain_experience,
        PS2.death,
        PS2.vehicle_destroy,
        PS2.player_login,
        PS2.player_logout,
        PS2.player_facility_capture,
        PS2.player_facility_defend,
        PS2.battle_rank_up,
        PS2.metagame_event,
        PS2.continent_unlock,
        PS2.continent_lock()
      ],
      worlds: ["all"],
      characters: ["all"]
    ]
  end
end
