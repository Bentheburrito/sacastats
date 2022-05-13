defmodule SacaStats.CensusCacheTest do
  use ExUnit.Case

  alias PS2.API.Query
  alias SacaStats.CensusCache

  setup_all do
    %{cache: start_supervised!(CensusCache)}
  end

  describe "CensusCache" do
    test "can put values", %{cache: cache} do
      value = %{"name" => %{"first" => "Bob"}}
      CensusCache.put(cache, 123, value)
      assert {:ok, ^value} = CensusCache.get(cache, 123)
    end

    test "can get values", %{cache: cache} do
      assert {:error, :not_found} = CensusCache.get(cache, :fake_key)

      value = %{"faction_id" => "2"}
      CensusCache.put(cache, 123, value)

      assert {:ok, ^value} = CensusCache.get(cache, 123)

      query = %Query{
        collection: "character",
        params: %{"character_id" => 321, "c:show" => "faction_id"}
      }

      fallback = {&PS2.API.query_one/2, [query, SacaStats.sid()]}

      assert {:error, :not_found} = CensusCache.get(cache, 321, fallback)

      query = %Query{
        query
        | params: %{"character_id" => 5_428_713_425_545_165_425, "c:show" => "faction_id"}
      }

      fallback = {&PS2.API.query_one/2, [query, SacaStats.sid()]}

      assert {:ok, ^value} = CensusCache.get(cache, 321, fallback)
    end
  end
end
