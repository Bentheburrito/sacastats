defmodule SacaStats.Poll do
  @moduledoc """
  Ecto schema for outfit polls.
  """

  use Ecto.Schema
  import Ecto.Changeset
  @primary_key {:id, :id, autogenerate: true}

  alias SacaStats.PollItem.{MultiChoice, Text}

  schema "polls" do
    field :owner_discord_id, :integer
    field :title, :string
    has_many :text_items, SacaStats.PollItem.Text
    has_many :multi_choice_items, SacaStats.PollItem.MultiChoice
  end

  def changeset(poll, params \\ %{}) do
    poll
    |> cast(params, [:owner_discord_id, :title])
    |> cast_assoc(:text_items, with: &Text.changeset/2)
    |> cast_assoc(:multi_choice_items, with: &MultiChoice.changeset/2)
  end

  def new_vote_changeset(poll, params) do
    poll
    |> cast(params, [:owner_discord_id, :title])
    |> cast_assoc(:text_items, with: &Text.new_vote_changeset/2)
    |> cast_assoc(:multi_choice_items, with: &MultiChoice.new_vote_changeset/2)
  end
end
