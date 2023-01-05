defmodule SacaStats.Repo.Migrations.AddFavoriteCharacters do
  use Ecto.Migration

  def change do
    create table(:favorite_characters) do
      add(:discord_id, :bigint)
      add(:character_id, :bigint)
      add(:last_known_name, :string)
    end
  end
end
