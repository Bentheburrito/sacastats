defmodule SacaStatsWeb.DiscordAuth do
  @moduledoc """
  Custom Discord OAuth2 solution.

  https://discord.com/developers/docs/topics/oauth2
  """

  require Logger

  alias SacaStats.{DiscordUser, Repo}

  @discord_api "https://discord.com/api"
  @authorize_url "https://discord.com/api/v10/oauth2/authorize"
  @token_url "https://discord.com/api/v10/oauth2/token"
  @revoke_url "https://discord.com/api/v10/oauth2/token/revoke"

  def gen_state do
    32
    |> :crypto.strong_rand_bytes()
    |> Base.encode64()
  end

  def authorize_url(state, scopes \\ "identify") do
    scopes = URI.encode(scopes)
    client_id = URI.encode(System.get_env("DISCORD_CLIENT_ID"))
    redirect_uri = URI.encode(System.get_env("OAUTH_REDIRECT_URI"))

    params = %{
      response_type: "code",
      client_id: client_id,
      scope: scopes,
      state: state,
      redirect_uri: redirect_uri,
      prompt: "consent"
    }

    @authorize_url <> "?" <> URI.encode_query(params, :rfc3986)
  end

  def get_access_token(auth_code) do
    body =
      %{
        client_id: System.get_env("DISCORD_CLIENT_ID"),
        client_secret: System.get_env("DISCORD_CLIENT_SECRET"),
        grant_type: "authorization_code",
        code: auth_code,
        redirect_uri: System.get_env("OAUTH_REDIRECT_URI")
      }
      |> URI.encode_query()

    headers = [{"Content-Type", "application/x-www-form-urlencoded"}]

    case HTTPoison.post(@token_url, body, headers) do
      {:ok, %HTTPoison.Response{body: token_body}} ->
        {:ok, Jason.decode!(token_body)}

      {:error, error} ->
        Logger.error("Error getting access token: #{inspect(error)}")
        {:error, error}
    end
  end

  def refresh_access_token(refresh_token) do
    body =
      %{
        client_id: System.get_env("DISCORD_CLIENT_ID"),
        client_secret: System.get_env("DISCORD_CLIENT_SECRET"),
        grant_type: "refresh_token",
        refresh_token: refresh_token
      }
      |> URI.encode_query()

    headers = [{"Content-Type", "application/x-www-form-urlencoded"}]

    case HTTPoison.post(@token_url, body, headers) do
      {:ok, %HTTPoison.Response{body: token_body}} ->
        {:ok, Jason.decode!(token_body)}

      {:error, error} ->
        Logger.error("Error getting access token: #{inspect(error)}")
        {:error, error}
    end
  end

  def revoke_token(token) do
    body =
      %{
        token: token
      }
      |> URI.encode_query()

    case HTTPoison.post(@revoke_url, body) do
      {:ok, %HTTPoison.Response{body: token_body}} ->
        {:ok, Jason.decode!(token_body)}

      {:error, error} ->
        Logger.error("Error getting access token: #{inspect(error)}")
        {:error, error}
    end
  end

  @doc """
  Fetch user attributes exposed by the `identify` scope.

  Returns {:ok, user} on success, {:error, HTTPoison.Error.t()} on HTTPoison error, and {:error, :nil_token} if token is
  nil.
  """
  def get_user(nil) do
    {:error, :nil_token}
  end

  def get_user(access_token) do
    headers = [{"Authorization", "Bearer #{access_token}"}]

    insert_opts = [
      on_conflict: {:replace_all_except, DiscordUser.non_updatable_fields()},
      conflict_target: :id
    ]

    with {:ok, user_response} <- HTTPoison.get(@discord_api <> "/users/@me", headers),
         {:ok, user_attrs} <- Jason.decode(user_response.body),
         changeset <- DiscordUser.changeset(%DiscordUser{}, user_attrs),
         {:ok, user} <- Repo.insert(changeset, insert_opts) do
      {:ok, user}
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        Logger.error("Could not insert user: #{inspect(changeset)}")
        {:error, changeset}

      {:ok, %HTTPoison.Response{status_code: 401}} ->
        {:error, :access_token_expired}

      error ->
        Logger.error("Error fetching user with access token: #{inspect(error)}")
        error
    end
  end
end
