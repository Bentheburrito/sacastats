defmodule SacaStatsWeb.DiscordAuth do
  use OAuth2.Strategy

  alias OAuth2.Client

  def new() do
    Client.new([
      strategy: __MODULE__,
      client_id: System.get_env("DISCORD_CLIENT_ID"),
      client_secret: System.get_env("DISCORD_CLIENT_SECRET"),
      redirect_uri: "http://lvh.me:4000/login/redir",
      site: "https://discord.com/api",
      authorize_url: "https://discord.com/api/oauth2/authorize",
      token_url: "https://discord.com/api/oauth2/token",
      params: %{state: gen_state()}
    ])
    |> Client.put_serializer("application/json", Jason)
  end

  def authorize_url!(%Client{} = client \\ new(), params \\ []) do
    scope = Keyword.get(params, :scope, "identify")
    Client.authorize_url!(client, scope: scope, state: client.params.state)
  end

  @spec get_token!(Client.t(), list(), list(), list()) :: Client.t()
  def get_token!(%Client{} = client \\ new(), params \\ [], headers \\ [], opts \\ []) do
    Client.get_token!(client, Keyword.put(params, :state, client.params.state), headers, opts)
  end

  def authorize_url(client, params) do
    OAuth2.Strategy.AuthCode.authorize_url(client, params)
  end

  def get_token(client, params, headers) do
    OAuth2.Strategy.AuthCode.get_token(client, params, headers)
  end

  @spec revoke_token(OAuth2.Client.t(), :access | :refresh) :: :ok | :error
  def revoke_token(client, token_type \\ :access) when token_type in [:access, :refresh] do
    body = %{
      token: Map.get(client.token, :"#{token_type}_token")
    }

    Client.post(client, "https://discord.com/api/oauth2/token/revoke", Jason.encode!(body))
    |> elem(0)
  end

  def get_user(client) do
    with {:ok, res} <- Client.get(client, "/users/@me"),
         url <- get_avatar_url(res.body["id"], res.body["avatar"]) do
      {:ok, Map.put(res.body, "avatar_url", url)}
    end
  end

  defp get_avatar_url(user_id, "a_" <> _rest = avatar_hash) do
    "https://cdn.discordapp.com/avatars/#{user_id}/#{avatar_hash}.gif"
  end

  defp get_avatar_url(user_id, avatar_hash) do
    "https://cdn.discordapp.com/avatars/#{user_id}/#{avatar_hash}.png"
  end

  defp gen_state() do
    32
    |> :crypto.strong_rand_bytes()
    |> Base.encode64()
  end
end
