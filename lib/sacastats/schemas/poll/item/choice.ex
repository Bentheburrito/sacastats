defmodule SacaStats.Poll.Item.Choice do
  @moduledoc """
  Ecto schema for a particular choice in a multiple-choice item of an outfit poll.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias SacaStats.Poll.Item

  schema "poll_item_choices" do
    field :description, :string
    belongs_to :item, Item

    timestamps()
  end

  def changeset(choice, params \\ %{}) do
    choice
    |> cast(params, [:description])
    |> validate_required([:description])
  end
end
