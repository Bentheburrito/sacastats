defmodule SacaStatsWeb.PageController do
  use SacaStatsWeb, :controller

  require Logger

  alias SacaStatsWeb.DiscordAuth

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def account(conn, _params) when conn.assigns.user in [false, nil] do
    redirect(conn, to: "/login")
  end

  def account(conn, _params) do
    render(conn, "account.html")
  end

  def login(conn, _params) do
    render(conn, "login.html")
  end

  def login_discord(conn, _params) do
    state = DiscordAuth.gen_state()
    auth_url = DiscordAuth.authorize_url(state)

    conn
    |> put_session(:discord_state, state)
    |> redirect(external: auth_url)
  end

  def login_discord_callback(conn, %{"error" => "access_denied", "state" => state}) do
    case get_session(conn, :discord_state) do
      ^state ->
        conn
        |> put_flash(
          :error,
          "It looks like you cancelled logging in with Discord. You can try again by clicking the button below"
        )
        |> redirect(to: "/login")

      real_state ->
        Logger.warning(
          "Login with Discord attempt failed.\nGot access_denied, and 'Discord' gave state #{state}, we have #{real_state}"
        )

        redirect(conn, "/")
    end
  end

  def login_discord_callback(conn, %{"code" => auth_code, "state" => state}) do
    with ^state <- get_session(conn, :discord_state),
         {:ok, %{"access_token" => access_token} = token_body} <-
           DiscordAuth.get_access_token(auth_code),
         {:ok, user} <- DiscordAuth.get_user(access_token) do
      conn
      |> delete_session(:discord_state)
      |> put_session(:discord_session, token_body)
      |> put_session(:user, user)
      |> put_flash(
        :info,
        "Successfully logged in - Welcome #{user.username}##{user.discriminator}!"
      )
      |> redirect(to: "/")
    else
      {:error, error} ->
        Logger.error(
          "Error occurred fetching Discord user after seemingly successful token fetch: #{inspect(error)}"
        )

        conn
        |> put_flash(:error, "Failed to fetch user info. Please try again soon.")
        |> redirect(to: "/login")

      {:ok, unexpected_body} ->
        Logger.error("Login with Discord attempt failed: #{inspect(unexpected_body)}")

        conn
        |> put_flash(:error, "Something went wrong while authenticating - please try again soon.")
        |> redirect(to: "/login")

      real_state ->
        Logger.warning(
          "Login with Discord attempt failed.\n'Discord' gave state #{state}, we have #{inspect(real_state)}"
        )

        conn
        |> put_flash(:error, "Something went wrong while authenticating - please try again soon.")
        |> redirect(to: "/login")
    end
  end

  def logout_discord(%Plug.Conn{} = conn, params) do
    %{"access_token" => access_token} = get_session(conn, :discord_session)
    DiscordAuth.revoke_token(access_token)

    redirect_to = Map.get(params, "redirect_to", "/")

    conn
    |> delete_session(:discord_session)
    |> delete_session(:user)
    |> put_flash(:info, "Successfully logged out.")
    |> redirect(to: redirect_to)
  end
end
