defmodule SacaStatsWeb.PollLive do
  @moduledoc """
  Helpers for poll LiveViews.
  """

  alias SacaStats.{Poll, Repo}

  def get_poll(id) do
    Poll
    |> Repo.get(id)
    |> Repo.preload(items: [:choices, :votes])
  end

  def get_voter_id(%{user: %{"id" => user_id}}), do: SacaStats.Utils.maybe_to_int(user_id)
  def get_voter_id(%{"user" => %{"id" => user_id}}), do: SacaStats.Utils.maybe_to_int(user_id)
  # anonymous voter
  def get_voter_id(_assigns), do: 0
end
