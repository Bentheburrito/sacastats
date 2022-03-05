defmodule SacaStats.PollItem.MultiChoice do
  @moduledoc """
  Ecto schema for a particular multiple-choice in an outfit poll.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "poll_items_multi_choice" do
    field :description, :string
    field :choices, {:array, :string}
    field :votes, {:map, :string} # Mapped by voter's discord_id => their selected choice
    field :position, :integer
    belongs_to :poll, SacaStats.Poll
  end

  def changeset(poll, params \\ %{}) do
    poll
    |> cast(params, [:type, :description, :votes, :position])
    |> validate_required([:poll_id, :description, :position])
  end
end
