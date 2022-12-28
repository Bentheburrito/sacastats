defmodule SacaStats.Census.OnlineStatus do
  @moduledoc """
  Ecto schema and API for getting characters from the /character collection, joining their stats.
  """

  alias PS2.API.{Query, QueryResult}
  alias SacaStats.Census.OnlineStatus

  import PS2.API.QueryBuilder, except: [field: 2]

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
  def status_text(%OnlineStatus{}), do: "online"

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
  Similar to `c:get_by_id/1`, but gets multiple online statuses by their IDs. Since getting multiple online statuses for many characters from
  the Census API is an expensive query (and may lead to timeouts), you can provide `true` for shallow copy to skip
  fetching character/weapon stats for uncached characters.
  """
  @spec get_many_by_id([integer()], boolean()) ::
          {:ok, %{integer() => Character.t() | :not_found}} | :error
  def get_many_by_id(id_list, _shallow_copy? \\ false) do
    {okay_map, _uncached_ids} =
      for character_id <- id_list, reduce: {_okay_map = %{}, _uncached_ids = []} do
        {okay_map, uncached_ids} ->
          with {:ok, %OnlineStatus{} = status} <- Cachex.get(:online_status_cache, character_id),
               {:ok, true} <-
                 Cachex.put(:online_status_cache, status.character_id, status) do
          else
            {:ok, nil} ->
              {Map.put(okay_map, character_id, :not_found), [character_id | uncached_ids]}

            {:error, _} ->
              Logger.error("Could not access :online_status_cache")
              :error
          end
      end

    {:ok, okay_map}
  end

  defp get_by_census(_query, attempt) when attempt == @max_attempts + 1, do: :error

  defp get_by_census(query, attempt) do
    with {:ok, %QueryResult{data: data}} <-
           PS2.API.query_one(query, SacaStats.SIDs.next()),
         {:ok, status} <-
           %OnlineStatus{} |> changeset(data) |> Ecto.Changeset.apply_action(:update) do
      Cachex.put(:online_status_cache, status.character_id, status)
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
