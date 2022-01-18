require Logger

defmodule SacaStatsWeb.CharacterController do
  use SacaStatsWeb, :controller
  alias SacaStatsWeb.CharacterView

  def character(conn, %{"character_name" => name, "stat_type" => "lookup"}) do
    redirect(conn, to: Routes.character_path(conn, :character, name, "general"))
  end

  def character(conn, %{"character_name" => name, "stat_type" => stat_template_name}) do
    q =
      PS2.API.Query.new(collection: "character")
      |> PS2.API.QueryBuilder.term("name.first_lower", String.downcase(name))
      |> PS2.API.QueryBuilder.resolve("online_status")

    case PS2.API.query_one(q) do
      {:ok, %PS2.API.QueryResult{returned: 0}} ->
        conn
        |> put_flash(:error, "The character '" <> name <> "' doesn't appear to exist.")
        |> redirect(to: Routes.character_path(conn, :character_search))

      {:ok, %PS2.API.QueryResult{data: body}} ->
        next_rank = Map.get(body, "battle_rank")
        {next_rank, ""} = Integer.parse(Map.get(next_rank, "value"))
        next_rank = next_rank + 1

        character_stuff = %{
          "stat_page" => String.downcase(stat_template_name) <> ".html",
          "response" => body,
          "next_rank" => next_rank
        }

        render(conn, "template.html", character: character_stuff)

      {:error, e} ->
        Logger.error("Error fetching character: #{inspect(e)}")
    end
  end

  def character_session(conn, %{"character_name" => name, "stat_type" => "session"}) do
    # case CAIData.API.get_session_by_name(name) do
    #   {:ok, session} ->
    #     character_stuff = %{"name" => name, "stat_page" => "session.html"}
    #     render(conn, "characterTemplate.html", character: character_stuff, session: session)

    #   :none ->
    #     conn
    #     |> put_flash(:error, "No session under a character with that name.")
    #     |> render("index.html")
    # end
  end

  def character_general(conn, %{"character_name" => _name}) do
    redirect(conn, to: conn.request_path <> "/general")
  end

  def character_search(conn, _params) do
    render(conn, "lookup.html")
  end

  def character_find(conn, _params) do
    conn = parse(conn)
    name = conn.params["character"]

    redirect(conn, to: Routes.character_path(conn, :character, name, "general"))
  end

  def parse(conn, opts \\ []) do
    opts = Keyword.put_new(opts, :parsers, [Plug.Parsers.URLENCODED, Plug.Parsers.MULTIPART])
    Plug.Parsers.call(conn, Plug.Parsers.init(opts))
  end
end
