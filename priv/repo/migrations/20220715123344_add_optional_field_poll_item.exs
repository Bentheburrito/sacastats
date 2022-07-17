defmodule SacaStats.Repo.Migrations.AddOptionalFieldPollItem do
  use Ecto.Migration

  def change do
    alter table(:poll_items) do
      add :optional, :boolean, default: false
    end
  end
end
