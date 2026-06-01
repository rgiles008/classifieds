defmodule Sunstate.Repo.Migrations.CreateZipCodes do
  use Ecto.Migration

  def change do
    create table(:zip_codes, primary_key: false) do
      add :zip, :string, primary_key: true
      add :city, :string, null: false
      add :county, :string
      add :latitude, :float, null: false
      add :longitude, :float, null: false

      timestamps()
    end

    create index(:zip_codes, [:city])
    create index(:zip_codes, [:county])
  end
end
