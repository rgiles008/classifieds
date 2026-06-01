defmodule Sunstate.Listings.Listing do
  use Ecto.Schema
  import Ecto.Changeset

  @price_types ~w(fixed negotiable free contact)
  @conditions ~w(new like_new good fair poor)
  @statuses ~w(active pending sold expired removed)

  schema "listings" do
    field :title, :string
    field :description, :string
    field :price, :decimal
    field :price_type, :string, default: "fixed"
    field :condition, :string
    field :status, :string, default: "active"

    # Location
    field :zip_code, :string
    field :city, :string
    field :state, :string, default: "FL"
    field :latitude, :float
    field :longitude, :float

    # Metrics
    field :view_count, :integer, default: 0
    field :favorite_count, :integer, default: 0

    # Dates
    field :expires_at, :utc_datetime
    field :featured_until, :utc_datetime

    belongs_to :user, Sunstate.Accounts.User
    belongs_to :category, Sunstate.Listings.Category
    has_many :images, Sunstate.Listings.ListingImage
    has_many :favorites, Sunstate.Listings.Favorite

    timestamps()
  end

  def changeset(listing, attrs) do
    listing
    |> cast(attrs, [
      :title, :description, :price, :price_type, :condition, :status,
      :zip_code, :city, :state, :latitude, :longitude,
      :expires_at, :featured_until, :user_id, :category_id
    ])
    |> validate_required([:title, :description, :price_type, :zip_code, :user_id])
    |> validate_length(:title, min: 5, max: 200)
    |> validate_length(:description, min: 10, max: 10_000)
    |> validate_number(:price, greater_than_or_equal_to: 0)
    |> validate_inclusion(:price_type, @price_types)
    |> validate_inclusion(:condition, @conditions)
    |> validate_inclusion(:status, @statuses)
    |> validate_format(:zip_code, ~r/^\d{5}$/, message: "must be a 5-digit zip code")
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:category_id)
  end

  def status_changeset(listing, status) do
    listing
    |> change(status: status)
    |> validate_inclusion(:status, @statuses)
  end
end
