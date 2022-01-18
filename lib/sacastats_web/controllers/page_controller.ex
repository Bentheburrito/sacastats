defmodule SacaStatsWeb.PageController do
  use SacaStatsWeb, :controller

  require Logger

  alias SacaStatsWeb.DiscordAuth

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def login(conn, _params) do
    render(conn, "login.html")
  end

  def login_discord(conn, _params) do
    client = DiscordAuth.new()
    auth_url = DiscordAuth.authorize_url!(client)

    conn
    |> put_session(:client, client)
    |> redirect(external: auth_url)
  end

  def login_discord_callback(conn, %{"code" => auth_code, "state" => state}) do
    with %OAuth2.Client{params: %{state: ^state}} = client <- get_session(conn, :client),
         client = DiscordAuth.get_token!(client, code: auth_code),
         {:ok, user} <- DiscordAuth.get_user(client) do
      conn
      |> put_session(:user, user)
      |> put_session(:client, client)
      |> put_flash(
        :info,
        "Successfully logged in - welcome #{user["username"]}##{user["discriminator"]}"
      )
      |> redirect(to: "/")
    else
      {:error, error} ->
        Logger.error(
          "Error occurred fetching Discord user after seemingly successful token fetch: #{inspect(error)}"
        )

        conn
        |> put_flash(:error, "failed to fetch user info. Please try again soon.")
        |> redirect(to: "/login")

      real_state ->
        Logger.warn(
          "Login with Discord attempt failed.\nDiscord gave state #{state}, client had #{real_state}"
        )

        conn
        |> put_flash(:error, "Something went wrong while authenticating - please try again soon.")
        |> redirect(to: "/login")
    end
  end

  def logout_discord(%Plug.Conn{} = conn, params) do
    DiscordAuth.revoke_token(get_session(conn, :client))

    redirect_to = Map.get(params, "redirect_to", "/")

    conn
    |> delete_session(:user)
    |> delete_session(:client)
    |> put_flash(:info, "Successfully logged out.")
    |> redirect(to: redirect_to)
  end

  def character(conn, %{"character_name" => name, "stat_type" => "session"}) do
    case SacaStats.get_sessions(:both, 10, :name, name) do
      {:ok, session} ->
        character_stuff = %{"name" => name, "stat_page" => "session.html"}
        render(conn, "characterTemplate.html", character: character_stuff, session: session)

      :error ->
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
