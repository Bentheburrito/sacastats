defmodule SacaStats.CharacterCache do
  @moduledoc """
  A cache for data retrieved from the "character" or "single_character_by_id" collections in the Census API.
  """
  use GenServer

  alias PS2.API.{Query, QueryResult}

  @type cache_result :: {:ok, value :: any()} | {:error, :not_found} | {:error, HTTPoison.Error.t() | Jason.DecodeError.t() | PS2.API.Error.t()}

  ### API

  def start_link(opts) when is_list(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @doc """
  Put a value in the cache under one or more keys. Returns `{:ok, value}` when the value passed is a proper value. If
  the value passed is a `t:PS2.API.Query.t/0`, the actual value will be fetched from the Census.
  """
  @spec put(cache :: pid() | atom(), key :: any(), value :: any()) :: cache_result()
  def put(cache, key, %Query{} = query) do
    case PS2.API.query_one(query, SacaStats.sid()) do
      {:ok, %QueryResult{returned: 0}} -> {:error, :not_found}
      {:ok, %QueryResult{data: data} } -> put(cache, key, data)
      {:error, error} -> {:error, error}
    end
  end

  def put(cache, key, value) when not is_list(key) do
    put(cache, [key], value)
  end

  def put(cache, keys, value) when is_pid(cache) or is_atom(cache) do
    GenServer.cast(cache, {:put, keys, value})
    {:ok, value}
  end

  @doc """
  Get a value from the cache under the specified key. Returns {:ok, value} if the key-value is present in the cache.
  If a fallback query is provided, the Census will be checked for the value and update the cache automatically if found.
  If the key-value is neither in the cache nor the Census, {:error, :not_found} is returned, or
  {:error, `t:PS2.API.Query.Error.t/0`} if the query failed.
  """
  @spec get(cache :: pid() | atom(), key :: any(), fallback_query :: PS2.API.Query.t() | nil) :: cache_result()
  def get(cache, key, fallback_query \\ nil) when is_pid(cache) or is_atom(cache) do
    GenServer.call(cache, {:get, key, fallback_query})
  end

  ### Impl

  @impl true
  def init(_) do
    {:ok, %{}}
  end

  @impl true
  def handle_call({:get, key, fallback_query}, _from, state) do
    result = case Map.fetch(state, key) do
      {:ok, value} -> {:ok, value}

      :error ->
        if not is_nil(fallback_query) do
          put(self(), key, fallback_query)
        else
          {:error, :not_found}
        end
    end
    {:reply, result, state}
  end

  @impl true
  def handle_cast({:put, keys, value}, state) do
    {:noreply, Enum.reduce(keys, state, &Map.put(&2, &1, value))}
  end
end
