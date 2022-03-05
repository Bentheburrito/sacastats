defmodule SacaStats.PollItem.Text do
  @moduledoc """
  Ecto schema for a particular text-response item in an outfit poll.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "poll_items_text" do
    field :description, :string
    field :votes, {:map, :string} # Mapped by voter's discord_id => their text response
    field :position, :integer
    belongs_to :poll, SacaStats.Poll
  end

  def changeset(poll, params \\ %{}) do
    poll
    |> cast(params, [:type, :description, :votes, :position])
    |> validate_required([:poll_id, :description, :position])
  end
end
