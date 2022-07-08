defmodule SacaStats.DiscordUser do
  @moduledoc """
  Ecto schema for a Discord User whose fields are made available by the "identify" scope.
  """

  use Ecto.Schema
  import Ecto.Changeset
  # maybe we should have a snowflake type?
  @primary_key {:id, :integer, []}

  alias SacaStats.DiscordUser

  schema "discord_users" do
    field :username, :string
    field :discriminator, :string
    field :avatar, :string
    field :bot, :boolean
    field :system, :boolean
    field :mfa_enabled, :boolean
    field :banner, :string
    field :accent_color, :integer
    field :locale, :string
    field :flags, :integer
    field :premium_type, :integer
    field :public_flags, :integer
  end

  @required_fields [
    :id,
    :username,
    :discriminator,
    :avatar
  ]

  @optional_fields [
    :bot,
    :system,
    :mfa_enabled,
    :banner,
    :accent_color,
    :locale,
    :flags,
    :premium_type,
    :public_flags
  ]

  def changeset(user, params \\ %{}) do
    user
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end

  def get_avatar_url(%DiscordUser{id: user_id, avatar: "a_" <> _rest = avatar_hash}) do
    "https://cdn.discordapp.com/avatars/#{user_id}/#{avatar_hash}.gif"
  end

  def get_avatar_url(%DiscordUser{id: user_id, avatar: avatar_hash}) do
    "https://cdn.discordapp.com/avatars/#{user_id}/#{avatar_hash}.png"
  end

  def non_updatable_fields do
    [:id, :bot]
  end
end
