defmodule SacaStats.Poll.Item.Vote do
  @moduledoc """
  Ecto schema for outfit poll votes.

  A `voter_discord_id` of 0 is considered an anonymous voter (they haven't logged in with Discord).
  """

  use Ecto.Schema
  import Ecto.Changeset
  @primary_key {:id, :id, autogenerate: true}

  alias SacaStats.Poll.Item

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
  end
end
