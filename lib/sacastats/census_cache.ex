defmodule SacaStats.CensusCache do
  @moduledoc """
  A cache for data retrieved from Census collections, such as "character" or "single_character_by_id".
  """
  use GenServer

  alias SacaStats.CensusCache

  @check_expired_interval_ms 20 * 1000

  defstruct data: %{},
            data_expirations: %{},
            fallback_fn: &CensusCache.default_fallback/1,
            entry_expiration_ms: :infinity

  @type cache_result :: {:ok, value :: any()} | {:error, :not_found}

  @type fallback_fn :: (key :: any() -> value :: any() | :not_found)

  ### API

  def start_link(opts) when is_list(opts) do
    {fallback_fn, opts} = Keyword.pop(opts, :fallback_fn, &default_fallback/1)
    {entry_expiration, opts} = Keyword.pop(opts, :entry_expiration_ms, :infinity)

    init_state = %CensusCache{
      data: %{},
      fallback_fn: fallback_fn,
      entry_expiration_ms: entry_expiration
    }

    GenServer.start_link(__MODULE__, init_state, opts)
  end

  @doc """
  Puts a value in the cache under one or more keys.
  """
  @spec put(cache :: pid() | atom(), key :: any(), value :: any()) :: :ok
  def put(cache, key, value) when not is_list(key) do
    put(cache, [key], value)
  end

  def put(cache, keys, value) when is_pid(cache) or is_atom(cache) do
    GenServer.cast(cache, {:put, keys, value})
  end

  @doc """
  Get a value from the cache under the specified key.

  Returns {:ok, value} if the key-value is present in the cache. If the key-value is not present, and a fallback
  function is provided, it will be lazily evaluated to obtain the value, and update the cache automatically. If no
  fallback is provided, or it returns `:not_found`, the cache will return `{:error, :not_found}`
  """
  @spec get(cache :: pid() | atom(), key :: any()) :: cache_result()
  def get(cache, key) when is_pid(cache) or is_atom(cache) do
    GenServer.call(cache, {:get, key})
  end

  @doc """
  Deletes any entries in the cache under one or more keys. Returns `:ok` even if some (or all) of the keys do not exist
  in the cache.
  """
  @spec delete(cache :: pid() | atom(), key :: any()) :: :ok
  def delete(cache, key) when not is_list(key) do
    delete(cache, [key])
  end

  def delete(cache, keys) do
    GenServer.cast(cache, {:delete, keys})
  end

  def default_fallback(_key), do: :not_found

  ### Impl

  @impl GenServer
  def init(%CensusCache{} = init_state) do
    Process.send_after(self(), :remove_expired, @check_expired_interval_ms)
    {:ok, init_state}
  end

  @impl GenServer
  def handle_call({:get, key}, _from, %CensusCache{data: data, fallback_fn: fallback_fn} = state) do
    case Map.get_lazy(data, key, fn -> fallback_fn.(key) end) do
      :not_found ->
        {:reply, {:error, :not_found}, state}

      value ->
        state = %CensusCache{
          state
          | data: Map.put_new(data, key, value),
            data_expirations:
              Map.put_new(
                state.data_expirations,
                key,
                System.os_time(:millisecond) + state.entry_expiration_ms
              )
        }

        {:reply, {:ok, value}, state}
    end
  end

  @impl GenServer
  def handle_cast({:put, keys, value}, %CensusCache{data: data} = state) do
    state = %CensusCache{
      state
      | data: Enum.reduce(keys, data, &Map.put(&2, &1, value)),
        data_expirations:
          Enum.reduce(
            keys,
            state.data_expirations,
            &Map.put(&2, &1, System.os_time(:millisecond) + state.entry_expiration_ms)
          )
    }

    {:noreply, state}
  end

  def handle_cast({:delete, keys}, %CensusCache{} = state) do
    state = do_delete(state, keys)

    {:noreply, state}
  end

  # message comes from the interval set in init/1
  @impl GenServer
  def handle_info(:remove_expired, %CensusCache{} = state) do
    cache = self()

    Task.start(fn ->
      keys_to_remove =
        for {key, expiration} <- state.data_expirations,
            System.os_time(:millisecond) > expiration do
          key
        end

      send(cache, {:remove_expired, keys_to_remove})
    end)

    Process.send_after(self(), :remove_expired, @check_expired_interval_ms)

    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:remove_expired, keys}, %CensusCache{} = state) do
    {:noreply, do_delete(state, keys)}
  end

  defp do_delete(%CensusCache{data: data} = state, keys) do
    %CensusCache{
      state
      | data: Map.drop(data, keys),
        data_expirations: Map.drop(data, keys)
    }
  end
end
