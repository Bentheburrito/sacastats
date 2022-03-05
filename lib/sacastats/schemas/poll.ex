defmodule SacaStats.Poll do
  @moduledoc """
  Ecto schema for outfit polls.
  """

  use Ecto.Schema
  import Ecto.Changeset
  @primary_key {:id, :id, autogenerate: true}

  schema "polls" do
    field :owner_discord_id, :integer
    field :title, :string
    has_many :text_items, SacaStats.PollItem.Text
    has_many :multi_choice_items, SacaStats.PollItem.MultiChoice
  end

  def changeset(poll, params \\ %{}) do
    poll
    |> cast(params, [:discord_id, ])
  end
end
