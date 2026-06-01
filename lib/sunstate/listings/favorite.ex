defmodule Sunstate.Listings.Favorite do
  use Ecto.Schema
  import Ecto.Changeset

  schema "favorites" do
    belongs_to :user, Sunstate.Accounts.User
    belongs_to :listing, Sunstate.Listings.Listing

    timestamps()
  end

  def changeset(favorite, attrs) do
    favorite
    |> cast(attrs, [:user_id, :listing_id])
    |> validate_required([:user_id, :listing_id])
    |> unique_constraint([:user_id, :listing_id])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:listing_id)
  end
end
