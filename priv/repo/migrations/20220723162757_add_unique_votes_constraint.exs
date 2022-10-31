defmodule SacaStats.Repo.Migrations.AddUniqueVotesConstraint do
  use Ecto.Migration

  def change do
    create unique_index(:poll_item_votes, [:voter_discord_id, :item_id])
  end
end
