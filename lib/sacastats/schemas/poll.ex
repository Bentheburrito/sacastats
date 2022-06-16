defmodule SacaStats.Poll do
  @moduledoc """
  Ecto schema for outfit polls.
  """

  use Ecto.Schema
  import Ecto.Changeset
  @primary_key {:id, :id, autogenerate: true}

  alias SacaStats.Poll.Item

  schema "polls" do
    field :owner_discord_id, :integer
    field :title, :string
    has_many :items, Item
  end

  def changeset(poll, params \\ %{}) do
    poll
    |> cast(params, [:owner_discord_id, :title])
    |> validate_required([:owner_discord_id, :title])
    |> cast_assoc(:items, with: &Item.changeset/2)
    |> validate_length(:items, min: 1)
  end

  defp validate_items(%Ecto.Changeset{changes: changes} = changeset) do
    total_len =
      Enum.count(Map.get(changes, :text_items, %{})) +
        Enum.count(Map.get(changes, :multi_choice_items, %{}))

    if total_len >= 1 do
      changeset
    else
      Ecto.Changeset.add_error(changeset, :items, "a poll must have at least one item to vote on")
    end
  end
end
