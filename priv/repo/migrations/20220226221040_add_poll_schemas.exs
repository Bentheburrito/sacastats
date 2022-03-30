defmodule SacaStats.Repo.Migrations.AddPollSchema do
  use Ecto.Migration

  def change do
    create table(:polls) do
      add :owner_discord_id, :integer
      add :title, :string
    end

    create table(:poll_items_text) do
      add :description, :string
      # Mapped by voter's discord_id => their text response
      add :votes, {:map, :string}
      add :position, :integer
      add :poll_id, references("polls")
    end

    create table(:poll_items_multi_choice) do
      add :description, :string
      add :choices, {:array, :string}
      # Mapped by voter's discord_id => their selected choice
      add :votes, {:map, :string}
      add :position, :integer
      add :poll_id, references("polls")
    end
  end
end
