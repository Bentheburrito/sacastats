defmodule SacaStats.CensusCache do
  @moduledoc """
  A cache for data retrieved from Census collections, such as "character" or "single_character_by_id".
  """
  use GenServer

  @type cache_result :: {:ok, value :: any()} | {:error, :not_found}

  @type fallback_fn :: (key :: any() -> value :: any() | :not_found)

  ### API

  def start_link(opts) when is_list(opts) do
    {fallback_fn, opts} = Keyword.pop(opts, :fallback_fn, nil)

    GenServer.start_link(__MODULE__, {nil, fallback_fn}, opts)
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

  ### Impl

  @impl true
  def init({_, nil}), do: {:ok, {%{}, fn _ -> :not_found end}}
  def init({_, fallback_fn}), do: {:ok, {%{}, fallback_fn}}

  @impl true
  def handle_call({:get, key}, _from, {state, fallback_fn}) do
    case Map.get_lazy(state, key, fn -> fallback_fn.(key) end) do
      :not_found ->
        {:reply, {:error, :not_found}, {state, fallback_fn}}

      value ->
        {:reply, {:ok, value}, {Map.put_new(state, key, value), fallback_fn}}
    end
  end

  @impl true
  def handle_cast({:put, keys, value}, {state, fallback_fn}) do
    {:noreply, {Enum.reduce(keys, state, &Map.put(&2, &1, value)), fallback_fn}}
  end
end
