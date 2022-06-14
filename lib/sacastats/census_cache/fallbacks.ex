defmodule SacaStats.CensusCache.Fallbacks do
  @moduledoc """
  Fallback functions for fetching new/refreshed data for census caches.
  """
  require Logger

  alias SacaStats.CensusCache
  alias PS2.API.{Join, Query}

  import PS2.API.QueryBuilder

  def character(key), do: character(key, 1)
  def character(_key, 4), do: :not_found

  def character(character_id_or_name, attempt) do
    {term, val} =
      if is_binary(character_id_or_name) do
        {"name.first_lower", String.downcase(character_id_or_name)}
      else
        {"character_id", character_id_or_name}
      end

    query =
      Query.new(collection: "character")
      |> term(term, val)
      |> resolve([
        "online_status",
        "outfit(alias,id,name,leader_character_id,time_created_date)",
        "weapon_stat",
        "weapon_stat_by_faction",
        "profile(profile_type_description)",
        "stat_history(stat_name,all_time)"
        # "stat(stat_name,value_forever)",
        # "stat_by_faction(stat_name,value_forever_vs,value_forever_nc,value_forever_tr)"
      ])
      |> join(
        Join.new(collection: "item_profile")
        |> on("items.item_id")
        |> to("item_id")
        |> list(true)
        |> show("profile_id")
        |> inject_at("classes_list")
      )
      |> lang("en")

    case PS2.API.query_one(query, SacaStats.sid()) do
      {:ok, %PS2.API.QueryResult{returned: 0}} ->
        :not_found

      {:ok, %PS2.API.QueryResult{data: data}} ->
        # put this data under their character id/name, as well
        other_key =
          (term == "character_id" && data["name"]["first_lower"]) ||
            String.to_integer(data["character_id"])

        CensusCache.put(SacaStats.CharacterCache, other_key, data)
        data

      {:error, e} ->
        Logger.warn("CharacterCache query returned error (#{attempt}/3): #{inspect(e)}")
        character(val, attempt + 1)
    end
  end

  def online_status(character_id) do
    query =
      Query.new(collection: "characters_online_status")
      |> term("character_id", character_id)

    case PS2.API.query_one(query, SacaStats.sid()) do
      {:ok, %PS2.API.QueryResult{returned: 0}} ->
        :not_found

      {:ok, %PS2.API.QueryResult{data: data}} ->
        (data["online_status"] == "0" && "offline") || "online"

      {:error, e} ->
        Logger.warn("OnlineStatusCache query returned error: #{inspect(e)}")
        :not_found
    end
  end
end
