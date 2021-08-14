defmodule SacaStatsWeb.PageController do
  use SacaStatsWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def character(conn, %{"character_name" => name, "stat_type" => "session"}) do
    case CAIData.API.get_session_by_name(name) do
      {:ok, session} ->
        character_stuff = %{"name" => name, "stat_page" => "session.html"}
        render(conn, "characterTemplate.html", character: character_stuff, session: session)
      :none ->
        conn
        |> put_flash(:error, "No session under a character with that name.")
        |> render("index.html")
    end
  end

  def character(conn, %{"character_name" => name, "stat_type" => stat_template_name}) do
    # Fetch character info from API and DB,
    character_stuff = %{"name" => name, "stat_page" => stat_template_name <> ".html"}
    render(conn, "characterTemplate.html", character: character_stuff)
  end

  def character(conn, _params) do
    # Fetch character info from API and DB,
    render(conn, "characterLookup.html")
  end
end
