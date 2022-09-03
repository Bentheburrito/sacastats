defmodule SacaStats.Repo.Migrations.AddDiscordUser do
  use Ecto.Migration

  def change do
    create table(:discord_users, primary_key: false) do
      add :id, :bigint, primary_key: true
      add :username, :string
      add :discriminator, :string
      add :avatar, :string
      add :bot, :boolean
      add :system, :boolean
      add :mfa_enabled, :boolean
      add :banner, :string
      add :accent_color, :integer
      add :locale, :string
      add :flags, :integer
      add :premium_type, :integer
      add :public_flags, :integer
    end
  end
end
