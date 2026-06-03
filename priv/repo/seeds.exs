# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs

alias Sunstate.Repo
alias Sunstate.Listings.Category

import Ecto.Query

# Only seed if categories table is empty
unless Repo.exists?(from c in Category, limit: 1) do
  categories = [
    %{name: "Vehicles", slug: "vehicles", icon: "hero-truck", position: 0},
    %{name: "Electronics", slug: "electronics", icon: "hero-device-phone-mobile", position: 1},
    %{name: "Furniture", slug: "furniture", icon: "hero-home", position: 2},
    %{name: "Clothing & Accessories", slug: "clothing", icon: "hero-shopping-bag", position: 3},
    %{name: "Home & Garden", slug: "home-garden", icon: "hero-sun", position: 4},
    %{name: "Sports & Outdoors", slug: "sports-outdoors", icon: "hero-trophy", position: 5},
    %{name: "Toys & Games", slug: "toys-games", icon: "hero-puzzle-piece", position: 6},
    %{name: "Baby & Kids", slug: "baby-kids", icon: "hero-face-smile", position: 7},
    %{name: "Musical Instruments", slug: "musical-instruments", icon: "hero-musical-note", position: 8},
    %{name: "Tools & Equipment", slug: "tools-equipment", icon: "hero-wrench-screwdriver", position: 9},
    %{name: "Pets & Supplies", slug: "pets", icon: "hero-heart", position: 10},
    %{name: "Free Stuff", slug: "free-stuff", icon: "hero-gift", position: 11},
    %{name: "Other", slug: "other", icon: "hero-squares-2x2", position: 12}
  ]

  now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

  Repo.insert_all(
    Category,
    Enum.map(categories, fn cat ->
      Map.merge(cat, %{inserted_at: now, updated_at: now})
    end)
  )

  IO.puts("Seeded #{length(categories)} categories")
end
