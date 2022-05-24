defmodule SacaStats.Repo.Migrations.AddPollSchema do
  use Ecto.Migration

  def change do
    create table(:polls) do
      add :owner_discord_id, :bigint
      add :title, :string
    end

    create table(:poll_items) do
      add :description, :string
      add :poll_id, references("polls")
    end

    create table(:poll_item_choices) do
      add :description, :string
      add :item_id, references("poll_items")
    end

    create table(:poll_item_votes) do
      add :voter_discord_id, :bigint
      add :content, :string
      add :item_id, references("poll_items")
    end
  end
end
