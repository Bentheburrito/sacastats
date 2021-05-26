defmodule SacaStatsWeb.PageController do
  use SacaStatsWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def character(conn, %{"character_name" => name, "stat_type" => stat_template_name}) do
    # Fetch character info from API and DB,
    character_stuff = %{"name" => name, "stat_page" => stat_template_name <> ".html"}
    render(conn, "characterTemplate.html", character: character_stuff)
  end

  def character(conn, _params) do
    # Fetch character info from API and DB,
    render(conn, "character.html")
  end
end
