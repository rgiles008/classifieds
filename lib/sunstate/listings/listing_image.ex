defmodule Sunstate.Listings.ListingImage do
  use Ecto.Schema
  import Ecto.Changeset

  schema "listing_images" do
    field :storage_key, :string
    field :variants, :map, default: %{}
    field :position, :integer, default: 0
    field :is_primary, :boolean, default: false

    belongs_to :listing, Sunstate.Listings.Listing

    timestamps()
  end

  def changeset(image, attrs) do
    image
    |> cast(attrs, [:storage_key, :variants, :position, :is_primary, :listing_id])
    |> validate_required([:storage_key, :listing_id])
    |> foreign_key_constraint(:listing_id)
  end
end
