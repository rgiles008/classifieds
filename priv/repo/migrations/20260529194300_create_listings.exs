defmodule Sunstate.Repo.Migrations.CreateListings do
  use Ecto.Migration

  def change do
    create table(:listings) do
      add :title, :string, null: false
      add :description, :text, null: false
      add :price, :decimal, precision: 10, scale: 2
      add :price_type, :string, null: false, default: "fixed"
      add :condition, :string
      add :status, :string, null: false, default: "active"

      # Location
      add :zip_code, :string, null: false
      add :city, :string
      add :state, :string, default: "FL"
      add :latitude, :float
      add :longitude, :float

      # Full-text search
      add :search_vector, :tsvector

      # Metrics
      add :view_count, :integer, default: 0
      add :favorite_count, :integer, default: 0

      # Dates
      add :expires_at, :utc_datetime
      add :featured_until, :utc_datetime

      # Relationships
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :category_id, references(:categories, on_delete: :nilify_all)

      timestamps()
    end

    create index(:listings, [:user_id])
    create index(:listings, [:category_id])
    create index(:listings, [:status])
    create index(:listings, [:zip_code])
    create index(:listings, [:price])
    create index(:listings, [:inserted_at])
    create index(:listings, [:expires_at])
    create index(:listings, [:featured_until])

    # GIN index for full-text search
    execute(
      "CREATE INDEX listings_search_vector_index ON listings USING gin(search_vector)",
      "DROP INDEX listings_search_vector_index"
    )

    # Trigger to auto-update search_vector
    execute(
      """
      CREATE OR REPLACE FUNCTION listings_search_vector_update() RETURNS trigger AS $$
      BEGIN
        NEW.search_vector :=
          setweight(to_tsvector('english', coalesce(NEW.title, '')), 'A') ||
          setweight(to_tsvector('english', coalesce(NEW.description, '')), 'B') ||
          setweight(to_tsvector('english', coalesce(NEW.city, '')), 'C');
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
      """,
      "DROP FUNCTION IF EXISTS listings_search_vector_update();"
    )

    execute(
      """
      CREATE TRIGGER listings_search_vector_trigger
      BEFORE INSERT OR UPDATE OF title, description, city ON listings
      FOR EACH ROW EXECUTE FUNCTION listings_search_vector_update();
      """,
      "DROP TRIGGER IF EXISTS listings_search_vector_trigger ON listings;"
    )
  end
end
