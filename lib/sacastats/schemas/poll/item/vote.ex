defmodule SacaStats.Poll.Item.Vote do
  @moduledoc """
  Ecto schema for outfit poll votes.

  A `voter_discord_id` of 0 is considered an anonymous voter (they haven't logged in with Discord).
  """

  use Ecto.Schema
  import Ecto.Changeset
  @primary_key {:id, :id, autogenerate: true}

  alias SacaStats.Poll.Item

  @no_dup_votes_message "you cannot vote twice in a poll. Editing poll votes/responses is currently not supported."

  schema "poll_item_votes" do
    field :voter_discord_id, :integer
    field :content, :string
    belongs_to :item, Item

    timestamps()
  end

  def changeset(vote, params \\ %{}) do
    vote
    |> cast(params, [:voter_discord_id, :content, :item_id])
    |> validate_required([:content, :item_id])
    |> unique_constraint([:voter_discord_id, :item_id], message: @no_dup_votes_message)
  end
end
