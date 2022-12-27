defmodule SacaStats.Repo.Migrations.AddVisibleResultsToPollItem do
  use Ecto.Migration

  def change do
    alter table(:poll_items) do
      add :visible_results, :boolean, default: true
    end
  end
end
