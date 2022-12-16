defmodule SacaStats.Census.Character.Outfit do
  use Ecto.Schema
  import Ecto.Changeset
  @primary_key false

  embedded_schema do
    field :outfit_id, :integer
    field :member_since_date, :utc_datetime
    field :name, :string
    field :alias, :string
    field :time_created_date, :utc_datetime
    field :leader_character_id, :integer
  end

  @fields [
    :outfit_id,
    :member_since_date,
    :name,
    :alias,
    :time_created_date,
    :leader_character_id
  ]

  def changeset(outfit, census_res \\ %{}) do
    params =
      census_res
      |> Map.put("member_since_date", format_census_date(census_res["member_since_date"]))
      |> Map.put("time_created_date", format_census_date(census_res["time_created_date"]))

    outfit
    |> cast(params, @fields)
    |> validate_required(@fields)
  end

  defp format_census_date(date_string) when date_string in [nil, ""], do: nil
  defp format_census_date(date_string), do: date_string <> "Z"
end
