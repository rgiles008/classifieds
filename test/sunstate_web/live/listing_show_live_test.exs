defmodule SunstateWeb.ListingShowLiveTest do
  use SunstateWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Sunstate.AccountsFixtures
  import Sunstate.ListingsFixtures

  describe "Listing show page" do
    setup do
      user = user_fixture()
      category = category_fixture()

      listing =
        listing_fixture(%{
          user: user,
          category: category,
          title: "Test Show Listing",
          description: "A detailed description of the test item for sale."
        })

      %{user: user, listing: listing}
    end

    test "displays listing details", %{conn: conn, listing: listing} do
      {:ok, _lv, html} = live(conn, ~p"/listings/#{listing.id}")
      assert html =~ "Test Show Listing"
      assert html =~ "A detailed description"
      assert html =~ "$99.99"
    end

    test "shows sign in prompt for unauthenticated users", %{conn: conn, listing: listing} do
      {:ok, _lv, html} = live(conn, ~p"/listings/#{listing.id}")
      assert html =~ "Sign in to contact seller"
    end

    test "shows contact seller button for authenticated users", %{conn: conn, listing: listing} do
      other_user = user_fixture()
      conn = log_in_user(conn, other_user)

      {:ok, _lv, html} = live(conn, ~p"/listings/#{listing.id}")
      assert html =~ "Contact Seller"
    end

    test "shows edit and mark sold buttons for owner", %{conn: conn, user: user, listing: listing} do
      conn = log_in_user(conn, user)

      {:ok, _lv, html} = live(conn, ~p"/listings/#{listing.id}")
      assert html =~ "Edit"
      assert html =~ "Mark as Sold"
    end

    test "allows owner to mark listing as sold", %{conn: conn, user: user, listing: listing} do
      conn = log_in_user(conn, user)

      {:ok, lv, _html} = live(conn, ~p"/listings/#{listing.id}")
      lv |> element("button", "Mark as Sold") |> render_click()

      assert render(lv) =~ "Listing marked as sold!"
    end

    test "allows authenticated user to toggle favorite", %{conn: conn, listing: listing} do
      other_user = user_fixture()
      conn = log_in_user(conn, other_user)

      {:ok, lv, _html} = live(conn, ~p"/listings/#{listing.id}")

      # Favorite
      lv |> element("#favorite-btn") |> render_click()
      html = render(lv)
      assert html =~ "hero-heart-solid"
    end

    test "increments view count for non-owners", %{conn: conn, listing: listing} do
      {:ok, _lv, _html} = live(conn, ~p"/listings/#{listing.id}")

      updated = Sunstate.Repo.get!(Sunstate.Listings.Listing, listing.id)
      # Mount is called for both static and connected render
      assert updated.view_count >= 1
    end
  end
end
