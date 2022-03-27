defmodule SacaStats.PollItem.Text do
  @moduledoc """
  Ecto schema for a particular text-response item in an outfit poll.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "poll_items_text" do
    field :description, :string
    field :votes, {:map, :string}, default: %{} # Mapped by voter's discord_id => their text response
    field :position, :integer
    belongs_to :poll, SacaStats.Poll
  end

  def changeset(text_item, params \\ %{}) do
    text_item
    |> cast(params, [:description, :position])
    |> validate_required([:description, :position])
  end

  def new_vote_changeset(text_item, params) do
    # Filter out votes with empty string or nil
    params = Map.update(params, "votes", %{}, fn votes ->
      votes
      |> Stream.filter(fn {_voter_id, response} -> response not in ["", nil] end)
      |> Enum.into(%{})
    end)

    text_item
    |> cast(params, [:votes])
  end
end
