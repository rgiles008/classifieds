defmodule Sunstate.ListingsTest do
  use Sunstate.DataCase, async: true

  alias Sunstate.Listings
  alias Sunstate.Listings.{Listing, Category, Favorite}

  import Sunstate.AccountsFixtures
  import Sunstate.ListingsFixtures

  ## Categories

  describe "categories" do
    test "list_categories/0 returns top-level categories ordered by position" do
      cat1 = category_fixture(%{name: "Autos", slug: "autos", position: 1})
      cat2 = category_fixture(%{name: "Electronics", slug: "electronics", position: 0})
      # subcategory should not appear in top-level
      category_fixture(%{name: "Phones", slug: "phones", parent_id: cat1.id})

      categories = Listings.list_categories()
      assert length(categories) == 2
      assert hd(categories).id == cat2.id
    end

    test "create_category/1 with valid data creates a category" do
      assert {:ok, %Category{} = category} =
               Listings.create_category(%{name: "Vehicles", slug: "vehicles"})

      assert category.name == "Vehicles"
      assert category.slug == "vehicles"
    end

    test "create_category/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Listings.create_category(%{name: nil, slug: nil})
    end

    test "create_category/1 enforces unique slug" do
      category_fixture(%{slug: "unique-slug"})
      assert {:error, changeset} = Listings.create_category(%{name: "Dup", slug: "unique-slug"})
      assert %{slug: ["has already been taken"]} = errors_on(changeset)
    end

    test "update_category/2 updates the category" do
      category = category_fixture()
      assert {:ok, %Category{} = updated} = Listings.update_category(category, %{name: "Updated"})
      assert updated.name == "Updated"
    end

    test "delete_category/1 deletes the category" do
      category = category_fixture()
      assert {:ok, %Category{}} = Listings.delete_category(category)
      assert_raise Ecto.NoResultsError, fn -> Listings.get_category!(category.id) end
    end

    test "get_category_by_slug!/1 returns the category" do
      category = category_fixture(%{slug: "test-slug"})
      assert Listings.get_category_by_slug!("test-slug").id == category.id
    end
  end

  ## Listings

  describe "listings" do
    setup do
      user = user_fixture()
      category = category_fixture()
      %{user: user, category: category}
    end

    test "create_listing/2 with valid data creates a listing", %{user: user, category: category} do
      attrs = %{
        title: "iPhone 15 Pro Max",
        description: "Excellent condition, barely used iPhone 15 Pro Max.",
        price: Decimal.new("999.99"),
        price_type: "fixed",
        condition: "like_new",
        zip_code: "32801",
        city: "Orlando",
        category_id: category.id
      }

      assert {:ok, %Listing{} = listing} = Listings.create_listing(user, attrs)
      assert listing.title == "iPhone 15 Pro Max"
      assert listing.status == "active"
      assert listing.view_count == 0
      assert listing.user_id == user.id
    end

    test "create_listing/2 with invalid data returns error changeset", %{user: user} do
      assert {:error, %Ecto.Changeset{}} = Listings.create_listing(user, %{})
    end

    test "create_listing/2 validates title length", %{user: user} do
      attrs = valid_listing_attributes(%{title: "Hey"})
      assert {:error, changeset} = Listings.create_listing(user, attrs)
      assert %{title: ["should be at least 5 character(s)"]} = errors_on(changeset)
    end

    test "create_listing/2 validates zip code format", %{user: user} do
      attrs = valid_listing_attributes(%{zip_code: "abc"})
      assert {:error, changeset} = Listings.create_listing(user, attrs)
      assert %{zip_code: ["must be a 5-digit zip code"]} = errors_on(changeset)
    end

    test "create_listing/2 validates price_type inclusion", %{user: user} do
      attrs = valid_listing_attributes(%{price_type: "barter"})
      assert {:error, changeset} = Listings.create_listing(user, attrs)
      assert %{price_type: [_]} = errors_on(changeset)
    end

    test "get_listing!/1 returns the listing with preloads", %{user: user, category: category} do
      listing = listing_fixture(%{user: user, category: category})
      fetched = Listings.get_listing!(listing.id)
      assert fetched.id == listing.id
      assert fetched.user.id == user.id
      assert fetched.category.id == category.id
    end

    test "update_listing/2 updates the listing", %{user: user, category: category} do
      listing = listing_fixture(%{user: user, category: category})
      assert {:ok, updated} = Listings.update_listing(listing, %{title: "Updated Title Here"})
      assert updated.title == "Updated Title Here"
    end

    test "delete_listing/1 deletes the listing", %{user: user, category: category} do
      listing = listing_fixture(%{user: user, category: category})
      assert {:ok, %Listing{}} = Listings.delete_listing(listing)
      assert_raise Ecto.NoResultsError, fn -> Listings.get_listing!(listing.id) end
    end

    test "mark_listing_sold/1 changes status to sold", %{user: user, category: category} do
      listing = listing_fixture(%{user: user, category: category})
      assert {:ok, sold} = Listings.mark_listing_sold(listing)
      assert sold.status == "sold"
    end

    test "increment_view_count/1 increments the counter", %{user: user, category: category} do
      listing = listing_fixture(%{user: user, category: category})
      assert listing.view_count == 0
      {:ok, updated} = Listings.increment_view_count(listing)
      assert updated.view_count == 1
    end

    test "change_listing/2 returns a changeset" do
      listing = %Listing{}
      assert %Ecto.Changeset{} = Listings.change_listing(listing)
    end
  end

  describe "list_listings/1" do
    setup do
      user = user_fixture()
      category = category_fixture(%{slug: "filter-cat"})
      %{user: user, category: category}
    end

    test "returns only active listings", %{user: user, category: category} do
      active = listing_fixture(%{user: user, category: category})
      sold = listing_fixture(%{user: user, category: category})
      Listings.mark_listing_sold(sold)

      listings = Listings.list_listings()
      ids = Enum.map(listings, & &1.id)
      assert active.id in ids
      refute sold.id in ids
    end

    test "filters by category_id", %{user: user, category: category} do
      other_cat = category_fixture(%{slug: "other-cat"})
      listing1 = listing_fixture(%{user: user, category: category})
      _listing2 = listing_fixture(%{user: user, category: other_cat})

      listings = Listings.list_listings(category_id: category.id)
      assert length(listings) == 1
      assert hd(listings).id == listing1.id
    end

    test "filters by zip_code", %{user: user, category: category} do
      l1 = listing_fixture(%{user: user, category: category, zip_code: "32801"})
      _l2 = listing_fixture(%{user: user, category: category, zip_code: "33101"})

      listings = Listings.list_listings(zip_code: "32801")
      assert length(listings) == 1
      assert hd(listings).id == l1.id
    end

    test "filters by price range", %{user: user, category: category} do
      _cheap = listing_fixture(%{user: user, category: category, price: Decimal.new("10.00")})
      mid = listing_fixture(%{user: user, category: category, price: Decimal.new("50.00")})
      _expensive = listing_fixture(%{user: user, category: category, price: Decimal.new("200.00")})

      listings = Listings.list_listings(min_price: Decimal.new("25.00"), max_price: Decimal.new("100.00"))
      assert length(listings) == 1
      assert hd(listings).id == mid.id
    end

    test "filters by condition", %{user: user, category: category} do
      _new_item = listing_fixture(%{user: user, category: category, condition: "new"})
      good = listing_fixture(%{user: user, category: category, condition: "good"})

      listings = Listings.list_listings(condition: "good")
      assert length(listings) == 1
      assert hd(listings).id == good.id
    end
  end

  describe "list_user_listings/1" do
    test "returns listings for a specific user" do
      user1 = user_fixture()
      user2 = user_fixture()
      category = category_fixture()

      l1 = listing_fixture(%{user: user1, category: category})
      _l2 = listing_fixture(%{user: user2, category: category})

      listings = Listings.list_user_listings(user1.id)
      assert length(listings) == 1
      assert hd(listings).id == l1.id
    end
  end

  describe "search_listings/2" do
    test "searches by title and description" do
      user = user_fixture()
      category = category_fixture()

      listing_fixture(%{
        user: user,
        category: category,
        title: "Vintage Guitar Fender",
        description: "A beautiful vintage Fender Stratocaster in great condition."
      })

      listing_fixture(%{
        user: user,
        category: category,
        title: "Mountain Bicycle Trek",
        description: "Barely used Trek mountain bike, perfect for trails."
      })

      results = Listings.search_listings("guitar")
      assert length(results) == 1
      assert hd(results).title =~ "Guitar"

      results = Listings.search_listings("bicycle")
      assert length(results) == 1
      assert hd(results).title =~ "Bicycle"
    end
  end

  ## Listing Images

  describe "listing images" do
    setup do
      user = user_fixture()
      category = category_fixture()
      listing = listing_fixture(%{user: user, category: category})
      %{listing: listing}
    end

    test "add_listing_image/2 adds an image to a listing", %{listing: listing} do
      assert {:ok, image} =
               Listings.add_listing_image(listing, %{
                 storage_key: "uploads/test.jpg",
                 variants: %{"thumbnail" => "uploads/test_thumb.jpg"},
                 position: 0,
                 is_primary: true
               })

      assert image.listing_id == listing.id
      assert image.storage_key == "uploads/test.jpg"
      assert image.is_primary == true
    end

    test "delete_listing_image/1 removes an image", %{listing: listing} do
      {:ok, image} =
        Listings.add_listing_image(listing, %{storage_key: "uploads/del.jpg"})

      assert {:ok, _} = Listings.delete_listing_image(image)
    end

    test "set_primary_image/2 sets the correct primary image", %{listing: listing} do
      {:ok, img1} = Listings.add_listing_image(listing, %{storage_key: "a.jpg", is_primary: true})
      {:ok, img2} = Listings.add_listing_image(listing, %{storage_key: "b.jpg"})

      {:ok, :ok} = Listings.set_primary_image(listing, img2.id)

      img1_reloaded = Repo.get!(Sunstate.Listings.ListingImage, img1.id)
      img2_reloaded = Repo.get!(Sunstate.Listings.ListingImage, img2.id)
      refute img1_reloaded.is_primary
      assert img2_reloaded.is_primary
    end
  end

  ## Favorites

  describe "favorites" do
    setup do
      user = user_fixture()
      category = category_fixture()
      listing = listing_fixture(%{user: user_fixture(), category: category})
      %{user: user, listing: listing}
    end

    test "toggle_favorite/2 adds a favorite", %{user: user, listing: listing} do
      assert {:ok, :favorited, %Favorite{}} = Listings.toggle_favorite(user.id, listing.id)
      assert Listings.user_favorited?(user.id, listing.id)
    end

    test "toggle_favorite/2 removes a favorite on second call", %{user: user, listing: listing} do
      {:ok, :favorited, _} = Listings.toggle_favorite(user.id, listing.id)
      assert {:ok, :unfavorited} = Listings.toggle_favorite(user.id, listing.id)
      refute Listings.user_favorited?(user.id, listing.id)
    end

    test "toggle_favorite/2 updates favorite_count on listing", %{user: user, listing: listing} do
      {:ok, :favorited, _} = Listings.toggle_favorite(user.id, listing.id)
      updated = Repo.get!(Listing, listing.id)
      assert updated.favorite_count == 1

      {:ok, :unfavorited} = Listings.toggle_favorite(user.id, listing.id)
      updated = Repo.get!(Listing, listing.id)
      assert updated.favorite_count == 0
    end

    test "user_favorited?/2 returns false when not favorited", %{user: user, listing: listing} do
      refute Listings.user_favorited?(user.id, listing.id)
    end

    test "list_user_favorites/1 returns user's favorited listings", %{user: user, listing: listing} do
      {:ok, :favorited, _} = Listings.toggle_favorite(user.id, listing.id)

      favorites = Listings.list_user_favorites(user.id)
      assert length(favorites) == 1
      assert hd(favorites).listing.id == listing.id
    end
  end
end
