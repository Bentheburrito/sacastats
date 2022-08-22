defmodule SacaStats.CensusCache.Fallbacks do
  @moduledoc """
  Fallback functions for fetching new/refreshed data for census caches.
  """
  require Logger

  alias SacaStats.CensusCache
  alias PS2.API.{Join, Query}

  import PS2.API.QueryBuilder

  @type key :: String.t() | integer()

  @spec character(key | [key], integer()) :: map() | :not_found
  def character(key), do: character(key, 1)
  def character(_key, 4), do: :not_found

  def character(character_id_or_name, attempt) do
    {term, val} = get_character_search_term(character_id_or_name)

    query =
      Query.new(collection: "character")
      |> term(term, val)
      |> resolve([
        "outfit(alias,id,name,leader_character_id,time_created_date)",
        "profile(profile_type_description)"
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

    case PS2.API.query(query, SacaStats.sid()) do
      {:ok, %PS2.API.QueryResult{returned: 0}} ->
        :not_found

      {:ok, %PS2.API.QueryResult{data: [data]}} ->
        # put this data under their character id/name, as well
        other_key =
          (term == "character_id" && data["name"]["first_lower"]) ||
            String.to_integer(data["character_id"])

        CensusCache.put(SacaStats.CharacterCache, other_key, data)

        unless is_list(character_id_or_name) do
          data
        else
          %{String.to_integer(data["character_id"]) => data}
        end

      {:ok, %PS2.API.QueryResult{data: data}} ->
        for character <- data, into: %{} do
          CensusCache.put(SacaStats.CharacterCache, character["name"]["first_lower"], character)
          {String.to_integer(character["character_id"]), character}
        end

      {:error, e} ->
        Logger.warning("CharacterCache query returned error (#{attempt}/3): #{inspect(e)}")
        character(character_id_or_name, attempt + 1)
    end
  end

  @spec character_stats(key | [key], integer()) :: map() | :not_found
  def character_stats(key), do: character_stats(key, 1)
  def character_stats(_key, 4), do: :not_found

  def character_stats(character_id_or_name, attempt) do
    {term, val} = get_character_search_term(character_id_or_name)

    query =
      Query.new(collection: "character")
      |> term(term, val)
      |> resolve([
        "stat_history(stat_name,all_time)",
        "stat(stat_name,value_forever)",
        "stat_by_faction(stat_name,value_forever_vs,value_forever_nc,value_forever_tr)"
      ])
      |> join(
        Join.new(collection: "characters_weapon_stat")
        |> inject_at("stats.weapons")
        |> list(true)
      )
      |> join(
        Join.new(collection: "characters_weapon_stat_by_faction")
        |> inject_at("stats.weapons_by_faction")
        |> list(true)
      )
      |> join(
        Join.new(collection: "item_profile")
        |> on("items.item_id")
        |> to("item_id")
        |> list(true)
        |> show("profile_id")
        |> inject_at("classes_list")
      )
      |> lang("en")

    case PS2.API.query(query, SacaStats.sid()) do
      {:ok, %PS2.API.QueryResult{returned: 0}} ->
        :not_found

      {:ok, %PS2.API.QueryResult{data: [data]}} ->
        # put this data under their character id/name, as well
        other_key =
          (term == "character_id" && data["name"]["first_lower"]) ||
            String.to_integer(data["character_id"])

        CensusCache.put(SacaStats.CharacterStatsCache, other_key, data)
        data

      {:ok, %PS2.API.QueryResult{data: data}} ->
        for character <- data, into: %{} do
          CensusCache.put(
            SacaStats.CharacterStatsCache,
            character["name"]["first_lower"],
            character
          )

          {String.to_integer(character["character_id"]), character}
        end

      {:error, e} ->
        Logger.warning("CharacterCache query returned error (#{attempt}/3): #{inspect(e)}")
        character_stats(character_id_or_name, attempt + 1)
    end
  end

  defp get_character_search_term(character_id_or_name) do
    character_id_or_name = SacaStats.Utils.maybe_to_int(character_id_or_name)

    cond do
      is_binary(character_id_or_name) ->
        {"name.first_lower", String.downcase(character_id_or_name)}

      is_list(character_id_or_name) ->
        {"character_id", Enum.join(character_id_or_name, ",")}

      :else ->
        {"character_id", character_id_or_name}
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
        Logger.warning("OnlineStatusCache query returned error: #{inspect(e)}")
        :not_found
    end
  end
end
