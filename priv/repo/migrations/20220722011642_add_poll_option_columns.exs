defmodule SacaStats.Repo.Migrations.AddPollOptionColumns do
  use Ecto.Migration

  def change do
    alter table(:polls) do
      add :visible_results, :boolean, default: false
      add :allow_anonymous_voters, :boolean, default: true
      add :allowed_voters, {:array, :bigint}, default: []
      add :close_poll_at, :utc_datetime
    end
  end
end
