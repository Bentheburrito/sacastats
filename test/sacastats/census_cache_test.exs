defmodule SacaStats.CensusCacheTest do
  use ExUnit.Case

  alias PS2.API.Query
  alias SacaStats.CensusCache

  setup_all do
    %{cache: start_supervised!({CensusCache, [fallback_fn: &census_char_fallback/1]})}
  end

  describe "CensusCache" do
    test "can put values", %{cache: cache} do
      value = %{"name" => %{"first" => "Bob"}}
      CensusCache.put(cache, 123, value)
      assert {:ok, ^value} = CensusCache.get(cache, 123)
    end

    test "can get values", %{cache: cache} do
      assert {:error, :not_found} = CensusCache.get(cache, "fake_key")

      value = %{"faction_id" => "2"}
      CensusCache.put(cache, 123, value)

      assert {:ok, ^value} = CensusCache.get(cache, 123)
      assert {:error, :not_found} = CensusCache.get(cache, 321)
      assert {:ok, ^value} = CensusCache.get(cache, 5_428_713_425_545_165_425)
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
