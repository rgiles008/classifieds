defmodule SunstateWeb.PageControllerTest do
  use SunstateWeb.ConnCase

  test "GET / renders the landing page", %{conn: conn} do
    conn = get(conn, ~p"/")
    html = html_response(conn, 200)
    assert html =~ "SunState"
    assert html =~ "Buy &" and html =~ "Sell in"
    assert html =~ "Browse Listings"
    assert html =~ "How It Works"
  end

  test "GET / shows categories", %{conn: conn} do
    conn = get(conn, ~p"/")
    html = html_response(conn, 200)
    assert html =~ "Browse by Category"
  end
end
