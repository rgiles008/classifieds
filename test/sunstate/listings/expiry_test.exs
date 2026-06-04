defmodule Sunstate.Listings.ExpiryTest do
  use Sunstate.DataCase, async: true

  alias Sunstate.Listings.Expiry

  import Sunstate.AccountsFixtures
  import Sunstate.ListingsFixtures

  describe "expire_old_listings/0" do
    test "expires listings past their expires_at date" do
      user = user_fixture()
      category = category_fixture()

      # Create a listing that expired yesterday
      past = DateTime.utc_now() |> DateTime.add(-86400) |> DateTime.truncate(:second)

      listing = listing_fixture(%{user: user, category: category})

      Sunstate.Listings.Listing
      |> Repo.get!(listing.id)
      |> Ecto.Changeset.change(expires_at: past)
      |> Repo.update!()

      assert Expiry.expire_old_listings() == 1

      updated = Repo.get!(Sunstate.Listings.Listing, listing.id)
      assert updated.status == "expired"
    end

    test "does not expire listings that haven't reached their expiry" do
      user = user_fixture()
      category = category_fixture()

      future = DateTime.utc_now() |> DateTime.add(86400) |> DateTime.truncate(:second)

      listing = listing_fixture(%{user: user, category: category})

      Sunstate.Listings.Listing
      |> Repo.get!(listing.id)
      |> Ecto.Changeset.change(expires_at: future)
      |> Repo.update!()

      assert Expiry.expire_old_listings() == 0

      updated = Repo.get!(Sunstate.Listings.Listing, listing.id)
      assert updated.status == "active"
    end
  end

  describe "set_default_expiry/1" do
    test "expires old listings without an expires_at" do
      user = user_fixture()
      category = category_fixture()

      listing = listing_fixture(%{user: user, category: category})

      # Backdate the listing to 31 days ago
      old_date = NaiveDateTime.utc_now() |> NaiveDateTime.add(-31 * 86400) |> NaiveDateTime.truncate(:second)

      Sunstate.Listings.Listing
      |> Repo.get!(listing.id)
      |> Ecto.Changeset.change(inserted_at: old_date)
      |> Repo.update!()

      assert Expiry.set_default_expiry(30) == 1

      updated = Repo.get!(Sunstate.Listings.Listing, listing.id)
      assert updated.status == "expired"
    end
  end
end
