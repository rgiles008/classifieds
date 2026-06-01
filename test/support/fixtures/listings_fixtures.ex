defmodule Sunstate.ListingsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Sunstate.Listings` context.
  """

  alias Sunstate.AccountsFixtures

  def valid_category_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      name: "Electronics #{System.unique_integer([:positive])}",
      slug: "electronics-#{System.unique_integer([:positive])}",
      icon: "cpu",
      position: 0
    })
  end

  def category_fixture(attrs \\ %{}) do
    {:ok, category} =
      attrs
      |> valid_category_attributes()
      |> Sunstate.Listings.create_category()

    category
  end

  def valid_listing_attributes(attrs \\ %{}) do
    user = attrs[:user] || AccountsFixtures.user_fixture()
    category = attrs[:category] || category_fixture()

    attrs
    |> Map.drop([:user, :category])
    |> Enum.into(%{
      title: "Test Listing Title",
      description: "This is a test listing with enough description text.",
      price: Decimal.new("99.99"),
      price_type: "fixed",
      condition: "good",
      zip_code: "32801",
      city: "Orlando",
      state: "FL",
      user_id: user.id,
      category_id: category.id
    })
  end

  def listing_fixture(attrs \\ %{}) do
    {:ok, listing} =
      attrs
      |> valid_listing_attributes()
      |> Sunstate.Listings.create_listing()

    listing
  end
end
