defmodule SacaStatsWeb.PageController do
  use SacaStatsWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def character(conn, %{"character_name" => name}) do
    # Fetch character info from API and DB,
    character_stuff = %{"name" => name}
    render(conn, "character.html", character: character_stuff)
  end
end
