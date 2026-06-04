defmodule Sunstate.LocationsTest do
  use Sunstate.DataCase, async: true

  alias Sunstate.Locations
  alias Sunstate.Locations.ZipCode

  describe "get_zip_code/1" do
    test "returns nil for nonexistent zip" do
      assert Locations.get_zip_code("99999") == nil
    end

    test "returns zip code when it exists" do
      Repo.insert!(%ZipCode{
        zip: "32801",
        city: "Orlando",
        county: "Orange",
        latitude: 28.5383,
        longitude: -81.3792
      })

      assert %ZipCode{city: "Orlando"} = Locations.get_zip_code("32801")
    end
  end

  describe "search_cities/1" do
    test "finds cities matching a query" do
      Repo.insert!(%ZipCode{zip: "32801", city: "Orlando", latitude: 28.5, longitude: -81.3})
      Repo.insert!(%ZipCode{zip: "33101", city: "Miami", latitude: 25.7, longitude: -80.1})

      results = Locations.search_cities("Orl")
      assert length(results) == 1
      assert hd(results).city == "Orlando"
    end

    test "returns empty list for no matches" do
      assert Locations.search_cities("Nonexistent") == []
    end
  end

  describe "zip_codes_within_radius/2" do
    test "returns zip codes within radius" do
      # Orlando area zips
      Repo.insert!(%ZipCode{zip: "32801", city: "Orlando", latitude: 28.5383, longitude: -81.3792})
      Repo.insert!(%ZipCode{zip: "32803", city: "Orlando", latitude: 28.5550, longitude: -81.3634})
      # Miami (far away)
      Repo.insert!(%ZipCode{zip: "33101", city: "Miami", latitude: 25.7617, longitude: -80.1918})

      results = Locations.zip_codes_within_radius("32801", 10)
      zips = Enum.map(results, & &1.zip)

      assert "32801" in zips
      assert "32803" in zips
      refute "33101" in zips
    end

    test "returns empty list for nonexistent zip" do
      assert Locations.zip_codes_within_radius("00000", 10) == []
    end
  end
end
