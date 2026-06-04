defmodule SunstateWeb.PageController do
  use SunstateWeb, :controller

  alias Sunstate.Listings

  def home(conn, _params) do
    categories = Listings.list_categories()
    recent_listings = Listings.list_listings() |> Enum.take(8)

    render(conn, :home,
      categories: categories,
      recent_listings: recent_listings
    )
  end
end
