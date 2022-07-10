defmodule SacaStatsWeb.PollLive do
  @moduledoc """
  Helpers for poll LiveViews.
  """

  import Ecto.Query

  alias SacaStats.{DiscordUser, Poll, Repo}

  def get_poll(id) do
    Poll
    |> preload(items: [:choices, :votes])
    |> Repo.get(id)
  end

  def get_voter_id(%{user: %DiscordUser{id: user_id}}) do
    SacaStats.Utils.maybe_to_int(user_id)
  end

  def get_voter_id(%{"user" => %DiscordUser{id: user_id}}) do
    SacaStats.Utils.maybe_to_int(user_id)
  end

  # anonymous voter
  def get_voter_id(_assigns), do: 0
end
