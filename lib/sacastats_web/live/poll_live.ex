defmodule SacaStatsWeb.PollLive do
  @moduledoc """
  Helpers for poll LiveViews.
  """

  import Ecto.Query

  alias SacaStats.{DiscordUser, Poll, Repo}
  alias Poll.Item
  alias Item.Vote

  def get_poll(id) do
    items_query =
      Item
      |> preload([:choices, :votes])
      |> order_by(:id)

    Poll
    |> preload(items: ^items_query)
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

  def allowed_voter?(_voter_id, %Poll{allowed_voters: []}), do: true

  def allowed_voter?(voter_id, %Poll{allowed_voters: allowed_voters}),
    do: voter_id in allowed_voters

  def poll_owner?(user_id, %Poll{owner_discord_id: owner_id}), do: user_id == owner_id
end
