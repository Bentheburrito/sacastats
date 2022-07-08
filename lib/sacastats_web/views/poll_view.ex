defmodule SacaStatsWeb.PollView do
  use SacaStatsWeb, :view
  import Phoenix.LiveView.Helpers

  def get_discord_username(0), do: "Anonymous"

  def get_discord_username(discord_id) do
    case SacaStats.Repo.get(SacaStats.DiscordUser, discord_id) do
      %SacaStats.DiscordUser{} = user ->
        user.username

      _ ->
        "Couldn't get Discord username"
    end
  end
end
