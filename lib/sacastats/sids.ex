defmodule SacaStats.SIDs do
  @moduledoc """
  This module is responsible for distributing SIDs.
  """
  use GenServer

  alias SacaStats.SIDs

  defstruct sids: [], used: []

  ### API

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %SIDs{sids: fetch_sids(), used: []}, name: __MODULE__)
  end

  def refresh do
    GenServer.cast(__MODULE__, :refresh)
  end

  def next do
    GenServer.call(__MODULE__, :next)
  end

  ### Impl

  def init(sids) do
    {:ok, sids}
  end

  def handle_cast(:refresh, _old_sids) do
    {:noreply, fetch_sids()}
  end

  def handle_call(:next, _from, %SIDs{used: used, sids: [next | sids]}) do
    {:reply, next, %SIDs{used: [next | used], sids: sids}}
  end

  def handle_call(:next, from, %SIDs{used: used, sids: []}) do
    sids = Enum.reverse(used)
    handle_call(:next, from, %SIDs{used: [], sids: sids})
  end

  defp fetch_sids do
    "SERVICE_ID_LIST"
    |> System.get_env(SacaStats.sid())
    |> parse_sids()
  end

  defp parse_sids(string_sids) do
    String.split(string_sids, ",", trim: true)
  end
end
