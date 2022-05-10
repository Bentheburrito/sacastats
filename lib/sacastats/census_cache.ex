defmodule SacaStats.CensusCache do
  @moduledoc """
  A cache for data retrieved from Census collections, such as "character" or "single_character_by_id".
  """
  use GenServer

  @type cache_result :: {:ok, value :: any()} | {:error, :not_found} |
    {:error, HTTPoison.Error.t() | Jason.DecodeError.t() | PS2.API.Error.t()}

  @type fallback_fn :: (... ->
    {:ok, PS2.API.QueryResult.t} | {:error, any()})

  ### API

  def start_link(opts) when is_list(opts) do
    GenServer.start_link(__MODULE__, nil, opts)
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

  Returns {:ok, value} if the key-value is present in the cache. If a fallback function is provided, it will be lazily
  evaluated to obtain the value, and update the cache automatically. The fallback function is expected to be either
  `c:PS2.API.query/3` or `c:PS2.API.query_one/3`, though a custom function can be provided as long as its returns are
  the same.

  If the key-value is neither in the cache nor retrieved by the fallback function, {:error, :not_found} is returned, or
  another error tuple if returned by the fallback function.
  """
  @spec get(cache :: pid() | atom(), key :: any(), {fallback_fn :: fallback_fn(), args :: [any()]} | nil) :: cache_result()
  def get(cache, key, fallback \\ nil) when is_pid(cache) or is_atom(cache) do
    GenServer.call(cache, {:get, key, fallback})
  end

  ### Impl

  @impl true
  def init(_) do
    {:ok, %{}}
  end

  @impl true
  def handle_call({:get, key, fallback}, _from, state) do
    {result, new_state} =
      case Map.fetch(state, key) do
        {:ok, value} -> {{:ok, value}, state}
        :error -> eval_fallback_fn(fallback, key, state)
      end

    {:reply, result, new_state}
  end

  @impl true
  def handle_cast({:put, keys, value}, state) do
    {:noreply, Enum.reduce(keys, state, &Map.put(&2, &1, value))}
  end

  defp eval_fallback_fn(nil, _key, cache_state), do: {{:error, :not_found}, cache_state}

  defp eval_fallback_fn({fallback_fn, args}, key, cache_state) do
    case apply(fallback_fn, args) do
      {:ok, %PS2.API.QueryResult{returned: 0}} -> {{:error, :not_found}, cache_state}
      {:ok, %PS2.API.QueryResult{data: data }} -> {{:ok, data}, Map.put(cache_state, key, data)}
      {:error, _e} = error -> {error, cache_state}
    end
  end
end
