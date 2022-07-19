defmodule SacaStats.Poll.Item do
  @moduledoc """
  Ecto schema for a particular item in an outfit poll.
  """

  use Ecto.Schema
  import Ecto.Changeset
  @primary_key {:id, :id, autogenerate: true}

  alias SacaStats.Poll
  alias SacaStats.Poll.Item
  alias SacaStats.Poll.Item.Vote

  schema "poll_items" do
    field :description, :string
    field :position, :integer
    field :optional, :boolean, default: false
    field :visible_results, :boolean, default: true
    has_many :choices, Item.Choice
    has_many :votes, Vote
    belongs_to :poll, Poll
  end

  def changeset(item, params \\ %{}) do
    item
    |> cast(params, [:description, :optional, :visible_results])
    |> validate_required([:description])
    |> cast_assoc(:choices, with: &Item.Choice.changeset/2)
    |> cast_assoc(:votes, with: &Vote.changeset/2)
  end

  def update_changeset(item, params \\ %{}) do
    cast(item, params, [:description, :optional, :visible_results])
  end
end
