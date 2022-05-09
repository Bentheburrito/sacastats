defmodule SacaStats.CharacterCacheTest do
  use ExUnit.Case

  alias SacaStats.CharacterCache
  alias PS2.API.Query

  setup_all do
    %{cache: start_supervised!(CharacterCache)}
  end

  describe "CharacterCache" do
    test "can put values", %{cache: cache} do
      value = %{"name" => %{"first" => "Bob"}}
      assert {:ok, ^value} = CharacterCache.put(cache, 123, value)

      query = %Query{
        collection: "character",
        params: %{"character_id" => 5428713425545165425, "c:show" => "faction_id"}
      }
      assert {:ok, %{"faction_id" => "2"}} = CharacterCache.put(cache, 123, query)
    end

    test "can get values", %{cache: cache} do
      assert {:error, :not_found} = CharacterCache.get(cache, :fake_key)

      value = %{"faction_id" => "2"}
      CharacterCache.put(cache, 123, value)

      assert {:ok, ^value} = CharacterCache.get(cache, 123)

      query = %Query{
        collection: "character",
        params: %{"character_id" => 321, "c:show" => "faction_id"}
      }
      assert {:error, :not_found} = CharacterCache.get(cache, 321, query)

      query = %Query{query | params: %{"character_id" => 5428713425545165425, "c:show" => "faction_id"}}
      assert {:ok, ^value} = CharacterCache.get(cache, 321, query)
    end
  end
end
