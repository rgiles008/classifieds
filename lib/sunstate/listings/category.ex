defmodule Sunstate.Listings.Category do
  use Ecto.Schema
  import Ecto.Changeset

  schema "categories" do
    field :name, :string
    field :slug, :string
    field :icon, :string
    field :position, :integer, default: 0

    belongs_to :parent, Sunstate.Listings.Category
    has_many :subcategories, Sunstate.Listings.Category, foreign_key: :parent_id
    has_many :listings, Sunstate.Listings.Listing

    timestamps()
  end

  def changeset(category, attrs) do
    category
    |> cast(attrs, [:name, :slug, :icon, :position, :parent_id])
    |> validate_required([:name, :slug])
    |> validate_length(:name, min: 2, max: 100)
    |> validate_format(:slug, ~r/^[a-z0-9\-]+$/, message: "must be lowercase with hyphens only")
    |> unique_constraint(:slug)
    |> foreign_key_constraint(:parent_id)
  end
end
