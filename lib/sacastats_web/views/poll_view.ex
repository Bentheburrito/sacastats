defmodule SacaStatsWeb.PollView do
  use SacaStatsWeb, :view
  import Phoenix.LiveView.Helpers

  def get_discord_username(0), do: "Anonymous"

  def get_discord_username(discord_id) do
    case SacaStats.CensusCache.get(SacaStats.DiscordClientCache, to_string(discord_id)) do
      {:ok, {_client, user}} ->
        user["username"]

      _ ->
        "Couldn't get Discord username"
    end
  end
end
