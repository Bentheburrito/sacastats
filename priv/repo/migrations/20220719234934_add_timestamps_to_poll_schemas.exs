defmodule SacaStats.Repo.Migrations.AddTimestampsToPollSchemas do
  use Ecto.Migration

  def change do
    alter table(:polls) do
      timestamps()
    end

    alter table(:poll_items) do
      timestamps()
    end

    alter table(:poll_item_choices) do
      timestamps()
    end

    alter table(:poll_item_votes) do
      timestamps()
    end
  end
end
