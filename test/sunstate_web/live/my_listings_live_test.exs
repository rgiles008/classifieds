defmodule SunstateWeb.MyListingsLiveTest do
  use SunstateWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Sunstate.AccountsFixtures
  import Sunstate.ListingsFixtures

  describe "My listings page" do
    setup :register_and_log_in_user

    test "renders my listings page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/my/listings")
      assert html =~ "My Listings"
    end

    test "shows user's listings", %{conn: conn, user: user} do
      category = category_fixture()
      listing_fixture(%{user: user, category: category, title: "My Posted Item"})

      {:ok, _lv, html} = live(conn, ~p"/my/listings")
      assert html =~ "My Posted Item"
    end

    test "does not show other users' listings", %{conn: conn} do
      other_user = user_fixture()
      category = category_fixture()
      listing_fixture(%{user: other_user, category: category, title: "Not My Item"})

      {:ok, _lv, html} = live(conn, ~p"/my/listings")
      refute html =~ "Not My Item"
    end

    test "allows deleting a listing", %{conn: conn, user: user} do
      category = category_fixture()
      listing = listing_fixture(%{user: user, category: category, title: "Delete Me"})

      {:ok, lv, _html} = live(conn, ~p"/my/listings")

      lv
      |> element(~s|button[phx-click="delete"][phx-value-id="#{listing.id}"]|)
      |> render_click()

      html = render(lv)
      refute html =~ "Delete Me"
    end
  end
end
