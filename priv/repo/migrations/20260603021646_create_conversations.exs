defmodule Sunstate.Repo.Migrations.CreateConversations do
  use Ecto.Migration

  def change do
    create table(:conversations) do
      add :listing_id, references(:listings, on_delete: :delete_all), null: false
      add :buyer_id, references(:users, on_delete: :delete_all), null: false
      add :seller_id, references(:users, on_delete: :delete_all), null: false
      add :last_message_at, :utc_datetime

      timestamps()
    end

    create unique_index(:conversations, [:listing_id, :buyer_id])
    create index(:conversations, [:buyer_id])
    create index(:conversations, [:seller_id])
    create index(:conversations, [:last_message_at])
  end
end
