require Logger

defmodule SacaStatsWeb.OutfitController do
  use SacaStatsWeb, :controller

  def general(conn, _params) do
    redirect(conn, to: conn.request_path <> "/poll")
  end

  def poll_lookup(conn, %{}) do
    render(conn, "poll-lookup.html")
  end
end
