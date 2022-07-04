defmodule SacaStats.CensusCacheTest do
  use ExUnit.Case

  alias PS2.API.Query
  alias SacaStats.CensusCache

  @entry_expiration_time 300

  setup do
    %{
      cache: start_supervised!({CensusCache, [entry_expiration_ms: @entry_expiration_time]})
    }
  end

  describe "CensusCache" do
    test "can put values", %{cache: cache} do
      value = %{"name" => %{"first" => "Bob"}}
      CensusCache.put(cache, 123, value)
      assert {:ok, ^value} = CensusCache.get(cache, 123)
    end

    test "can get values", %{cache: cache} do
      assert {:error, :not_found} = CensusCache.get(cache, 123)

      value = %{"faction_id" => "2"}
      CensusCache.put(cache, 123, value)

      assert {:ok, ^value} = CensusCache.get(cache, 123)
      assert {:error, :not_found} = CensusCache.get(cache, 321)
    end

    test "entries expire after the given `entry_expiration_ms` milliseconds have passed since entry's been put",
         %{cache: cache} do
      assert {:error, :not_found} = CensusCache.get(cache, 123)

      value = %{"faction_id" => "2"}
      CensusCache.put(cache, 123, value)

      assert {:ok, ^value} = CensusCache.get(cache, 123)

      # this is a bit hacky, but we wait for the entry to expire, then prompt the CensusCache to remove expired
      # entries, then wait another 100ms for the Task to complete before making a :not_found assertion
      Process.sleep(@entry_expiration_time + 50)
      send(cache, :remove_expired)
      Process.sleep(100)

      assert {:error, :not_found} = CensusCache.get(cache, 123)
    end
  end

  defp census_char_fallback(key), do: census_char_fallback(key, 1)
  defp census_char_fallback(key, 3), do: :not_found

  defp census_char_fallback(key, attempt) do
    query = %Query{
      collection: "character",
      params: %{"character_id" => key, "c:show" => "faction_id"}
    }

    case PS2.API.query_one(query, SacaStats.sid()) do
      {:ok, %PS2.API.QueryResult{returned: 0}} ->
        :not_found

      {:ok, %PS2.API.QueryResult{data: data}} ->
        data

      {:error, e} ->
        IO.puts("Query returned error: #{inspect(e)}")
        census_char_fallback(key, attempt + 1)
    end
  end
end
