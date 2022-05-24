defmodule SacaStats.Poll.Vote do
  @moduledoc """
  Ecto schema for outfit poll votes.
  """

  use Ecto.Schema
  import Ecto.Changeset
  @primary_key {:id, :id, autogenerate: true}

  alias SacaStats.Poll.Item

  schema "poll_item_votes" do
    field :voter_discord_id, :integer
    field :content, :string
    belongs_to :item, Item
  end

  def changeset(vote, params \\ %{}) do
    vote
    |> cast(params, [:voter_discord_id, :content])
    |> validate_required([:voter_discord_id, :content])
  end
end
