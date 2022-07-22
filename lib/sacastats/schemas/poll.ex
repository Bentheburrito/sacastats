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

    timestamps()
  end

  def changeset(poll, params \\ %{}) do
    poll
    |> cast(params, [:owner_discord_id, :title])
    |> validate_required([:owner_discord_id, :title, :items])
    |> cast_assoc(:items, with: &Item.changeset/2, required: true)
    |> validate_length(:items, min: 1)
  end
end
