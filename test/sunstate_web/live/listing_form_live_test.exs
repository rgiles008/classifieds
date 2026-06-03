defmodule SunstateWeb.ListingFormLiveTest do
  use SunstateWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Sunstate.AccountsFixtures
  import Sunstate.ListingsFixtures

  describe "New listing page" do
    setup :register_and_log_in_user

    test "renders new listing form", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/listings/new")
      assert html =~ "New Listing"
      assert html =~ "listing-form"
    end

    test "redirects unauthenticated users" do
      conn = build_conn()
      result = get(conn, ~p"/listings/new")
      assert redirected_to(result) == ~p"/users/log_in"
    end

    test "validates form on change", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/listings/new")

      result =
        lv
        |> element("#listing-form")
        |> render_change(listing: %{"title" => "Hi", "description" => "short"})

      assert result =~ "should be at least 5 character"
    end

    test "creates listing on valid submit", %{conn: conn} do
      category = category_fixture()
      {:ok, lv, _html} = live(conn, ~p"/listings/new")

      lv
      |> form("#listing-form",
        listing: %{
          "title" => "Brand New iPhone",
          "description" => "Selling my brand new iPhone 15 Pro, never used.",
          "price" => "999.99",
          "price_type" => "fixed",
          "condition" => "new",
          "zip_code" => "32801",
          "city" => "Orlando",
          "category_id" => category.id
        }
      )
      |> render_submit()

      {path, _flash} = assert_redirect(lv)
      assert path =~ ~r"/listings/\d+"
    end
  end

  describe "Edit listing page" do
    setup :register_and_log_in_user

    setup %{user: user} do
      category = category_fixture()
      listing = listing_fixture(%{user: user, category: category, title: "Original Title"})
      %{listing: listing}
    end

    test "renders edit listing form", %{conn: conn, listing: listing} do
      {:ok, _lv, html} = live(conn, ~p"/listings/#{listing.id}/edit")
      assert html =~ "Edit Listing"
      assert html =~ "Original Title"
    end

    test "updates listing on valid submit", %{conn: conn, listing: listing} do
      {:ok, lv, _html} = live(conn, ~p"/listings/#{listing.id}/edit")

      lv
      |> form("#listing-form", listing: %{"title" => "Updated Title Here"})
      |> render_submit()

      assert_redirect(lv, ~p"/listings/#{listing.id}")
    end

    test "prevents editing another user's listing", %{conn: conn} do
      other_user = user_fixture()
      category = category_fixture()
      other_listing = listing_fixture(%{user: other_user, category: category})

      {:ok, _lv, html} =
        live(conn, ~p"/listings/#{other_listing.id}/edit")
        |> follow_redirect(conn)

      assert html =~ "You can only edit your own listings"
    end
  end
end
