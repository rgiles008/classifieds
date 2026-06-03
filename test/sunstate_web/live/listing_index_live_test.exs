defmodule SunstateWeb.ListingIndexLiveTest do
  use SunstateWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Sunstate.AccountsFixtures
  import Sunstate.ListingsFixtures

  describe "Listing index page" do
    test "renders listings page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/listings")
      assert html =~ "listing"
    end

    test "displays active listings", %{conn: conn} do
      user = user_fixture()
      category = category_fixture()

      _listing =
        listing_fixture(%{
          user: user,
          category: category,
          title: "Beautiful Couch For Sale"
        })

      {:ok, _lv, html} = live(conn, ~p"/listings")
      assert html =~ "Beautiful Couch For Sale"
    end

    test "does not display sold listings", %{conn: conn} do
      user = user_fixture()
      category = category_fixture()

      listing =
        listing_fixture(%{
          user: user,
          category: category,
          title: "Already Sold Item"
        })

      Sunstate.Listings.mark_listing_sold(listing)

      {:ok, _lv, html} = live(conn, ~p"/listings")
      refute html =~ "Already Sold Item"
    end

    test "filters listings by category", %{conn: conn} do
      user = user_fixture()
      cat1 = category_fixture(%{name: "Tech", slug: "tech-filter"})
      cat2 = category_fixture(%{name: "Autos", slug: "autos-filter"})

      listing_fixture(%{user: user, category: cat1, title: "Cool Laptop Here"})
      listing_fixture(%{user: user, category: cat2, title: "Fast Honda Civic"})

      {:ok, _lv, html} = live(conn, ~p"/listings?#{%{category: "tech-filter"}}")
      assert html =~ "Cool Laptop Here"
      refute html =~ "Fast Honda Civic"
    end

    test "searches listings", %{conn: conn} do
      user = user_fixture()
      category = category_fixture()

      listing_fixture(%{
        user: user,
        category: category,
        title: "Vintage Stratocaster Guitar"
      })

      listing_fixture(%{
        user: user,
        category: category,
        title: "Mountain Bike Trek"
      })

      {:ok, lv, _html} = live(conn, ~p"/listings")
      _html = lv |> element("#search-form") |> render_change(%{"q" => "guitar"})

      # After search patch, re-render
      {:ok, _lv, html} = live(conn, ~p"/listings?#{%{q: "guitar"}}")
      assert html =~ "Stratocaster"
      refute html =~ "Mountain Bike"
    end
  end
end
