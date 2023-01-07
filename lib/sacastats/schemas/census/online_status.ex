defmodule SacaStats.Census.OnlineStatus do
  @moduledoc """
  Ecto schema and API for getting characters from the /character collection, joining their stats.
  """

  alias PS2.API.{Query, QueryResult}
  alias SacaStats.Census.OnlineStatus

  import PS2.API.QueryBuilder, except: [field: 2]

  @cache_ttl_ms 12 * 60 * 60 * 1000
  def put_opts, do: [ttl: @cache_ttl_ms]
  @httpoison_timeout_ms 6 * 1000
  @max_attempts 3
  @query_base Query.new(collection: "characters_online_status") |> lang("en")

  require Logger

  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :character_id, :integer, primary_key: true
    field :online_status, :integer
  end

  def changeset(online_status, census_res \\ %{}) do
    online_status
    |> cast(census_res, [:character_id, :online_status])
    |> validate_required([:character_id, :online_status])
  end

  def status_text(%OnlineStatus{online_status: 0}), do: "offline"
  def status_text(%OnlineStatus{online_status: 1}), do: "online"
  def status_text(_), do: "unknown"

  @spec get_by_id(integer()) :: {:ok, struct()} | :not_found | :error
  def get_by_id(character_id) do
    case Cachex.get(:online_status_cache, character_id) do
      {:ok, %OnlineStatus{} = status} ->
        {:ok, status}

      {:ok, nil} ->
        query = term(@query_base, "character_id", character_id)
        get_by_census(query, _attempt = 1)

      {:error, _} ->
        Logger.error("Could not access :online_status_cache")
        :error
    end
  end

  @doc """
  Similar to `c:get_by_id/1`, but gets multiple characters' online statuses by their IDs.
  """
  @spec get_many_by_id([integer()]) ::
          {:ok, %{integer() => Character.t() | :not_found}} | :error
  def get_many_by_id(id_list) do
    {okay_map, uncached_ids} =
      for character_id <- id_list, reduce: {_okay_map = %{}, _uncached_ids = []} do
        {okay_map, uncached_ids} ->
          case Cachex.get(:online_status_cache, character_id) do
            {:ok, %OnlineStatus{} = status} ->
              {Map.put(okay_map, character_id, {:ok, status}), uncached_ids}

            {:ok, nil} ->
              {Map.put(okay_map, character_id, :not_found), [character_id | uncached_ids]}

            {:error, _} ->
              Logger.error("Could not access :online_status_cache")
              :error
          end
      end

    case get_uncached_ids(okay_map, uncached_ids) do
      :error -> :error
      okay_map -> {:ok, okay_map}
    end
  end

  def get_uncached_ids(okay_map, []), do: okay_map

  def get_uncached_ids(okay_map, uncached_ids) do
    query = term(@query_base, "character_id", uncached_ids)

    case PS2.API.query(query, SacaStats.SIDs.next(), recv_timeout: @httpoison_timeout_ms) do
      {:ok, %QueryResult{returned: 0}} ->
        okay_map

      {:ok, %QueryResult{data: data}} ->
        update_okay_map(okay_map, data)

      {:error, error} ->
        Logger.error(
          "Could not parse census characters_online_status response into an OnlineStatus struct: #{inspect(error)}"
        )

        :error
    end
  end

  defp update_okay_map(okay_map, census_data) do
    for char_params <- census_data, reduce: okay_map do
      result_map ->
        %OnlineStatus{}
        |> OnlineStatus.changeset(char_params)
        |> Ecto.Changeset.apply_action(:update)
        |> case do
          {:ok, %OnlineStatus{} = status} ->
            Cachex.put(:online_status_cache, status.character_id, status, put_opts())

            Map.put(result_map, status.character_id, {:ok, status})

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
    with {:ok, %QueryResult{data: data}} <-
           PS2.API.query_one(query, SacaStats.SIDs.next()),
         {:ok, status} <-
           %OnlineStatus{} |> changeset(data) |> Ecto.Changeset.apply_action(:update) do
      Cachex.put(:online_status_cache, status.character_id, status, put_opts())
      {:ok, status}
    else
      {:ok, %QueryResult{returned: 0}} ->
        :not_found

      {:error, _} ->
        Logger.error("Could not parse census online status response into an OnlineStatus struct")
        :error

      {:error, e} ->
        Logger.warning("CharacterCache query returned error (#{attempt}/3): #{inspect(e)}")
        get_by_census(query, attempt + 1)
    end
  end
end
