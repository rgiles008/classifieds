defmodule Sunstate.Repo.Migrations.CreateCategories do
  use Ecto.Migration

  def change do
    create table(:categories) do
      add :name, :string, null: false
      add :slug, :string, null: false
      add :icon, :string
      add :position, :integer, default: 0
      add :parent_id, references(:categories, on_delete: :delete_all)

      timestamps()
    end

    create unique_index(:categories, [:slug])
    create index(:categories, [:parent_id])
    create index(:categories, [:position])
  end
end
