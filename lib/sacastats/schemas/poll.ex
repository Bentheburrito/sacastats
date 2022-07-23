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
    field :visible_results, :boolean, default: false
    field :allow_anonymous_voters, :boolean, default: true
    field :allowed_voters, {:array, :integer}, default: []
    field :close_poll_at, :utc_datetime
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

  def update_changeset(poll, params \\ %{}) do
    allowed_voters_length = params |> Map.get("allowed_voters", []) |> length()

    params =
      if allowed_voters_length > 0 &&
           Enum.at(Map.get(params, "allowed_voters"), allowed_voters_length - 1) == "" do
        Map.update!(params, "allowed_voters", &List.delete_at(&1, -1))
      else
        params
      end

    poll
    |> cast(params, [
      :title,
      :visible_results,
      :allow_anonymous_voters,
      :allowed_voters,
      :close_poll_at
    ])
    |> validate_change(:close_poll_at, fn _, %DateTime{} = dt ->
      if DateTime.compare(dt, DateTime.utc_now()) == :lt do
        [close_poll_at: "cannot be less than the current date and time"]
      else
        []
      end
    end)
  end
end
