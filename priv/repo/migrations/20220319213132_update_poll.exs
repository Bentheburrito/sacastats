defmodule SacaStats.Repo.Migrations.UpdatePoll do
  use Ecto.Migration

  def change do
    alter table(:polls) do
      modify :owner_discord_id, :bigint
    end
  end
end
