defmodule SacaStats.Characters do
  @moduledoc """
  Context module for character and character stat related functions and schemas
  """

  alias PS2.API.{Join, Query, QueryResult}
  alias SacaStats.Census.Character
  alias SacaStats.Character.Favorite
  alias SacaStats.Repo

  import Ecto.Query
  import PS2.API.QueryBuilder, except: [field: 2]
  import SacaStats.Utils

  @httpoison_timeout_ms 10 * 1000
  @max_attempts 3
  @query_base Query.new(collection: "character")
              |> resolve([
                "outfit(alias,id,name,leader_character_id,time_created_date)",
                "profile(profile_type_description)",
                "stat_history(stat_name,all_time)",
                "stat(stat_name,value_forever)",
                "stat_by_faction(stat_name,value_forever_vs,value_forever_nc,value_forever_tr)"
              ])
              |> join(
                Join.new(collection: "characters_weapon_stat")
                |> inject_at("weapon_stat")
                |> list(true)
              )
              |> join(
                Join.new(collection: "characters_weapon_stat_by_faction")
                |> inject_at("weapon_stat_by_faction")
                |> list(true)
              )
              |> lang("en")

  @shallow_query_base Query.new(collection: "character")
                      |> show([
                        "character_id",
                        "name",
                        "faction_id",
                        "profile_id",
                        "title_id",
                        "head_id",
                        "battle_rank",
                        "prestige_level"
                      ])
                      |> lang("en")

  require Logger

  def get_sex(faction_id, _head_id) when faction_id in [0, 4], do: "robot"
  def get_sex(_faction_id, head_id) when head_id <= 4, do: "male"
  def get_sex(_faction_id, head_id) when head_id > 4, do: "female"

  def get_ethnicity(faction_id, _head_id) when faction_id in [0, 4], do: "robot"
  def get_ethnicity(_faction_id, head_id) when head_id in [1, 5], do: "caucasian"
  def get_ethnicity(_faction_id, head_id) when head_id in [2, 6], do: "african"
  def get_ethnicity(_faction_id, head_id) when head_id in [3, 7], do: "asian"
  def get_ethnicity(_faction_id, head_id) when head_id in [4, 8], do: "hispanic"

  def get_stat_by_name(nil, _name), do: 0

  def get_stat_by_name(stats, name) do
    stats
    |> Enum.find(&(&1.stat_name == name))
    |> Map.get(:all_time)
    |> maybe_to_int(0)
  end

  @spec get_by_id(integer()) :: {:ok, struct()} | :not_found | :error
  def get_by_id(character_id) do
    with {:ok, %Character{} = char} <- Cachex.get(:character_cache, character_id),
         {:ok, true} <- Cachex.put(:character_cache, char.name_first_lower, char.character_id) do
      {:ok, char}
    else
      {:ok, nil} ->
        query = term(@query_base, "character_id", character_id)
        get_by_census(query, _attempt = 1)

      {:error, _} ->
        Logger.error("Could not access :character_cache")
        :error
    end
  end

  @spec get_by_name(String.t()) :: {:ok, struct()} | :not_found | :error
  def get_by_name(name) do
    name_lower = String.downcase(name)

    case Cachex.get(:character_cache, name_lower) do
      {:ok, nil} ->
        query = term(@query_base, "name.first_lower", name_lower)
        get_by_census(query, _attempt = 1)

      {:ok, character_id} ->
        get_by_id(character_id)
    end
  end

  @doc """
  Similar to `c:get_by_id/1`, but gets multiple characters by their IDs. Since getting stats for many characters from
  the Census API is an expensive query (and may lead to timeouts), you can provide `true` for shallow copy to skip
  fetching character/weapon stats for uncached characters.
  """
  @spec get_many_by_id([integer()], boolean()) ::
          {:ok, %{integer() => Character.t() | :not_found}} | :error
  def get_many_by_id(id_list, shallow_copy? \\ false) do
    # `okay_map` are the IDs found in the cache pointing to their :ok tuples, and non-cached IDs pointing to :not_found
    # `uncached_ids` are the IDs not found in the cache that need to get fetched from the census.
    {okay_map, uncached_ids} =
      for character_id <- id_list, reduce: {_okay_map = %{}, _uncached_ids = []} do
        {okay_map, uncached_ids} ->
          with {:ok, %Character{} = char} <- Cachex.get(:character_cache, character_id),
               {:ok, true} <-
                 Cachex.put(:character_cache, char.name_first_lower, char.character_id) do
            {Map.put(okay_map, character_id, {:ok, char}), uncached_ids}
          else
            {:ok, nil} ->
              {Map.put(okay_map, character_id, :not_found), [character_id | uncached_ids]}

            {:error, _} ->
              Logger.error("Could not access :character_cache")
              :error
          end
      end

    case get_uncached_ids(okay_map, uncached_ids, shallow_copy?) do
      :error -> :error
      okay_map -> {:ok, okay_map}
    end
  end

  def get_uncached_ids(okay_map, [], _shallow_copy?), do: okay_map

  def get_uncached_ids(okay_map, uncached_ids, shallow_copy?) do
    {query, changeset_fn} =
      if shallow_copy? do
        {term(@shallow_query_base, "character_id", uncached_ids), &Character.shallow_changeset/2}
      else
        {term(@query_base, "character_id", uncached_ids), &Character.changeset/2}
      end

    case PS2.API.query(query, SacaStats.SIDs.next(), recv_timeout: @httpoison_timeout_ms) do
      {:ok, %QueryResult{returned: 0}} ->
        okay_map

      {:ok, %QueryResult{data: data}} ->
        update_okay_map(okay_map, data, changeset_fn, shallow_copy?)

      {:error, error} ->
        Logger.error(
          "Could not parse census character response into a Character struct: #{inspect(error)}"
        )

        :error
    end
  end

  defp update_okay_map(okay_map, census_data, changeset_fn, shallow_copy?) do
    for char_params <- census_data, reduce: okay_map do
      result_map ->
        %Character{}
        |> changeset_fn.(char_params)
        |> Ecto.Changeset.apply_action(:update)
        |> case do
          {:ok, %Character{} = char} ->
            # Only cache these responses if they contain character/weapon stats
            unless shallow_copy? do
              Cachex.put(:character_cache, char.character_id, char)
              Cachex.put(:character_cache, char.name_first_lower, char.character_id)
            end

            Map.put(result_map, char.character_id, {:ok, char})

          {:error, error} ->
            Logger.error(
              "Couldn't make a changeset (changeset: #{inspect(error)}) from params: #{inspect(char_params)}"
            )

            result_map
        end
    end
  end

  defp get_by_census(_query, attempt) when attempt == @max_attempts + 1, do: :error

  defp get_by_census(query, attempt) do
    with {:ok, %QueryResult{data: data, returned: returned}} when returned > 0 <-
           PS2.API.query_one(query, SacaStats.SIDs.next()),
         {:ok, char} <-
           %Character{} |> Character.changeset(data) |> Ecto.Changeset.apply_action(:update) do
      Cachex.put(:character_cache, char.character_id, char)
      Cachex.put(:character_cache, char.name_first_lower, char.character_id)
      {:ok, char}
    else
      {:ok, %QueryResult{returned: 0}} ->
        :not_found

      {:error, error} ->
        Logger.error(
          "Could not parse census character response into a Character struct: #{inspect(error)}"
        )

        :error

      {:error, e} ->
        Logger.warning("CharacterCache query returned error (#{attempt}/3): #{inspect(e)}")
        get_by_census(query, attempt + 1)
    end
  end

  def get_rank_string(battle_rank, prestige) do
    if prestige > 0 do
      "ASP #{prestige} BR #{battle_rank}"
    else
      "BR #{battle_rank}"
    end
  end

  def favorite?(id, user_id) do
    if is_nil(user_id) do
      false
    else
      case from(f in Favorite,
             select: f,
             where: f.discord_id == ^user_id and f.character_id == ^id
           )
           |> Repo.all() do
        [] ->
          false

        [_favorite_character] ->
          true
      end
    end
  end
end
