defmodule SacaStatsWeb.PollLive do
  @moduledoc """
  Helpers for poll LiveViews.
  """

  import Ecto.Query

  alias SacaStats.{DiscordUser, Poll, Repo}
  alias Poll.Item
  alias Item.Vote

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

  def has_voted?(%DiscordUser{id: user_id}, %Poll{} = poll) do
    has_voted?(user_id, poll)
  end

  def has_voted?(user_id, %Poll{items: poll_items}) do
    Enum.any?(poll_items, fn %Item{} = item ->
      Enum.any?(item.votes, fn %Vote{} = vote ->
        vote.voter_discord_id == user_id
      end)
    end)
  end
end
