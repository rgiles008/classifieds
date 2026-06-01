defmodule Sunstate.Repo.Migrations.CreateFavorites do
  use Ecto.Migration

  def change do
    create table(:favorites) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :listing_id, references(:listings, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:favorites, [:user_id, :listing_id])
    create index(:favorites, [:listing_id])
  end
end
