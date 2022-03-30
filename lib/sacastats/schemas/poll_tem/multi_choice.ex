defmodule SacaStats.PollItem.MultiChoice do
  @moduledoc """
  Ecto schema for a particular multiple-choice in an outfit poll.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "poll_items_multi_choice" do
    field :description, :string
    field :choices, {:array, :string}
    field :votes, {:map, :string}, default: %{} # Mapped by voter's discord_id => their selected choice
    field :position, :integer
    belongs_to :poll, SacaStats.Poll
  end

  def changeset(multi_choice_item, params \\ %{}) do
    # Parse possible string `choices` into a list, like
    # "red, green, blue" => ["red", "green", "blue"]
    params =
      if is_map_key(params, "choices") do
        Map.update!(params, "choices", fn
          str_choices when is_binary(str_choices) ->
            str_choices
            |> String.split(",")
            |> Enum.map(&String.trim/1)
          choices when is_list(choices) ->
            choices
        end)
      else
        params
      end

    multi_choice_item
    |> cast(params, [:description, :position, :choices])
    |> validate_required([:description, :position, :choices])
    |> validate_change(:choices, fn :choices, choices ->
      if length(choices) >= 2 and nil not in choices and "" not in choices do
        []
      else
        [choices: "must have at least two non-empty choices"]
      end
    end)
  end

  def new_vote_changeset(multi_choice_item, params) do
    multi_choice_item
    |> cast(params, [:votes])
  end
end
