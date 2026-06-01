defmodule Sunstate.Repo.Migrations.CreateListingImages do
  use Ecto.Migration

  def change do
    create table(:listing_images) do
      add :storage_key, :string, null: false
      add :variants, :map, default: %{}
      add :position, :integer, default: 0
      add :is_primary, :boolean, default: false

      add :listing_id, references(:listings, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:listing_images, [:listing_id])
    create index(:listing_images, [:listing_id, :position])
  end
end
