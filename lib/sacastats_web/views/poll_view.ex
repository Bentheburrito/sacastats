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
      vote_distributions =
        cond do
          length(item.choices) > 0 and length(item.votes) > 0 ->
            for {choice, count} <- Enum.frequencies_by(item.votes, & &1.content) do
              "#{choice}: #{Float.round(count / length(item.votes) * 100, 2)}%"
            end

          length(item.choices) > 0 ->
            ["No votes for this item"]

          :else ->
            ["N/A (text field)"]
        end

      %{
        item: item,
        response_rate: Float.round(length(item.votes) / total_num_voters * 100, 2),
        vote_distributions: Enum.join(vote_distributions, ", ")
      }
    end
  end
end
