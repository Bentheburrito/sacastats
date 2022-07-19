defmodule SacaStatsWeb.PollView do
  use SacaStatsWeb, :view
  import Phoenix.LiveView.Helpers

  alias SacaStats.Poll
  alias Poll.Item

  def get_discord_username(0), do: "Anonymous"

  def get_discord_username(discord_id) do
    case SacaStats.Repo.get(SacaStats.DiscordUser, discord_id) do
      %SacaStats.DiscordUser{} = user ->
        user.username

      _ ->
        "Couldn't get Discord username"
    end
  end

  def summarize_poll(%Poll{} = poll, total_num_voters) do
    for %Item{} = item <- poll.items do
      %{
        item_id: item.id,
        response_rate: Float.round(length(item.votes) / total_num_voters * 100, 2)
      }
      |> Map.merge(multi_choice_summary(item))
    end
  end

  def get_vote_distributions_svg(distributions) do
    opts = [
      mapping: %{category_col: "Choice", value_col: "Percentage"},
      colour_palette: ["fbb4ae", "b3cde3", "ccebc5"],
      legend_setting: :legend_right,
      # data_labels: true,
      title: "Vote Distributions"
    ]

    distributions
    |> Contex.Dataset.new(["Choice", "Percentage"])
    |> Contex.Plot.new(Contex.PieChart, 450, 250, opts)
    |> Contex.Plot.to_svg()
  end

  def get_vote_distributions(%Item{} = item) do
    for {choice, count} <- vote_frequencies_with_defaults(item) do
      {choice, Float.round(count / length(item.votes) * 100, 2)}
    end
  end

  defp multi_choice_summary(item) do
    cond do
      length(item.choices) > 0 and length(item.votes) > 0 ->
        vote_distributions = get_vote_distributions(item)

        friendly_vote_distributions =
          Enum.map_join(vote_distributions, ", ", fn {choice, percentage} ->
            "#{choice}: #{percentage}%"
          end)

        %{
          vote_distributions: friendly_vote_distributions,
          pie_chart: get_vote_distributions_svg(vote_distributions)
        }

      length(item.choices) > 0 ->
        %{
          vote_distributions: "No votes for this item",
          pie_chart: "A chart will appear here once someone votes"
        }

      :else ->
        %{
          vote_distributions: "N/A (text field)",
          pie_chart: "N/A (text field)"
        }
    end
  end

  defp vote_frequencies_with_defaults(item) do
    frequencies = Enum.frequencies_by(item.votes, & &1.content)

    item.choices
    |> Map.new(&{&1.description, 0})
    |> Map.merge(frequencies)
  end
end
