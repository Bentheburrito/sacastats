defmodule SacaStats.Repo.Migrations.CascadeDeletePollItemsVotesChoices do
  use Ecto.Migration

  def change do
    drop_if_exists constraint(:poll_items, "poll_items_poll_id_fkey")

    alter table(:poll_items) do
      modify :poll_id, references("polls", on_delete: :delete_all)
    end

    drop_if_exists constraint(:poll_item_choices, "poll_item_choices_item_id_fkey")

    alter table(:poll_item_choices) do
      modify :item_id, references("poll_items", on_delete: :delete_all)
    end

    drop_if_exists constraint(:poll_item_votes, "poll_item_votes_item_id_fkey")

    alter table(:poll_item_votes) do
      modify :item_id, references("poll_items", on_delete: :delete_all)
    end
  end
end
