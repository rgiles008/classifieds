defmodule Sunstate.Listings do
  @moduledoc """
  The Listings context.
  """

  import Ecto.Query
  alias Sunstate.Repo
  alias Sunstate.Listings.{Listing, Category, ListingImage, Favorite}

  ## Categories

  def list_categories do
    Category
    |> where([c], is_nil(c.parent_id))
    |> order_by([c], c.position)
    |> preload(:subcategories)
    |> Repo.all()
  end

  def get_category!(id), do: Repo.get!(Category, id)

  def get_category_by_slug!(slug), do: Repo.get_by!(Category, slug: slug)

  def create_category(attrs) do
    %Category{}
    |> Category.changeset(attrs)
    |> Repo.insert()
  end

  def update_category(%Category{} = category, attrs) do
    category
    |> Category.changeset(attrs)
    |> Repo.update()
  end

  def delete_category(%Category{} = category) do
    Repo.delete(category)
  end

  ## Listings

  def list_listings(opts \\ []) do
    Listing
    |> where([l], l.status == "active")
    |> filter_listings(opts)
    |> order_by([l], [desc: l.featured_until, desc: l.inserted_at])
    |> preload([:category, :user, :images])
    |> Repo.all()
  end

  defp filter_listings(query, []), do: query

  defp filter_listings(query, [{:category_id, id} | rest]) when not is_nil(id) do
    query |> where([l], l.category_id == ^id) |> filter_listings(rest)
  end

  defp filter_listings(query, [{:zip_code, zip} | rest]) when is_binary(zip) do
    query |> where([l], l.zip_code == ^zip) |> filter_listings(rest)
  end

  defp filter_listings(query, [{:min_price, min} | rest]) when not is_nil(min) do
    query |> where([l], l.price >= ^min) |> filter_listings(rest)
  end

  defp filter_listings(query, [{:max_price, max} | rest]) when not is_nil(max) do
    query |> where([l], l.price <= ^max) |> filter_listings(rest)
  end

  defp filter_listings(query, [{:condition, condition} | rest]) when is_binary(condition) do
    query |> where([l], l.condition == ^condition) |> filter_listings(rest)
  end

  defp filter_listings(query, [{:user_id, user_id} | rest]) when not is_nil(user_id) do
    query |> where([l], l.user_id == ^user_id) |> filter_listings(rest)
  end

  defp filter_listings(query, [{:search, term} | rest]) when is_binary(term) and term != "" do
    tsquery = term |> String.split() |> Enum.join(" & ")

    query
    |> where([l], fragment("search_vector @@ to_tsquery('english', ?)", ^tsquery))
    |> filter_listings(rest)
  end

  defp filter_listings(query, [_ | rest]), do: filter_listings(query, rest)

  def get_listing!(id) do
    Listing
    |> preload([:category, :user, :images])
    |> Repo.get!(id)
  end

  def create_listing(%Sunstate.Accounts.User{} = user, attrs) do
    %Listing{user_id: user.id}
    |> Listing.changeset(attrs)
    |> Repo.insert()
  end

  def update_listing(%Listing{} = listing, attrs) do
    listing
    |> Listing.changeset(attrs)
    |> Repo.update()
  end

  def delete_listing(%Listing{} = listing) do
    Repo.delete(listing)
  end

  def change_listing(%Listing{} = listing, attrs \\ %{}) do
    Listing.changeset(listing, attrs)
  end

  def mark_listing_sold(%Listing{} = listing) do
    listing
    |> Listing.status_changeset("sold")
    |> Repo.update()
  end

  def increment_view_count(%Listing{} = listing) do
    {1, _} =
      Listing
      |> where(id: ^listing.id)
      |> Repo.update_all(inc: [view_count: 1])

    {:ok, %{listing | view_count: listing.view_count + 1}}
  end

  def list_user_listings(user_id) do
    Listing
    |> where([l], l.user_id == ^user_id)
    |> order_by([l], desc: l.inserted_at)
    |> preload([:category, :images])
    |> Repo.all()
  end

  ## Listing Images

  def add_listing_image(%Listing{} = listing, attrs) do
    %ListingImage{listing_id: listing.id}
    |> ListingImage.changeset(attrs)
    |> Repo.insert()
  end

  def delete_listing_image(%ListingImage{} = image) do
    Repo.delete(image)
  end

  def set_primary_image(%Listing{} = listing, image_id) do
    Repo.transaction(fn ->
      # Unset all primary flags for this listing
      ListingImage
      |> where([i], i.listing_id == ^listing.id)
      |> Repo.update_all(set: [is_primary: false])

      # Set the specified image as primary
      {1, _} =
        ListingImage
        |> where([i], i.id == ^image_id and i.listing_id == ^listing.id)
        |> Repo.update_all(set: [is_primary: true])

      :ok
    end)
  end

  ## Favorites

  def toggle_favorite(user_id, listing_id) do
    case Repo.get_by(Favorite, user_id: user_id, listing_id: listing_id) do
      nil ->
        %Favorite{}
        |> Favorite.changeset(%{user_id: user_id, listing_id: listing_id})
        |> Repo.insert()
        |> case do
          {:ok, favorite} ->
            update_favorite_count(listing_id)
            {:ok, :favorited, favorite}

          error ->
            error
        end

      %Favorite{} = favorite ->
        Repo.delete(favorite)
        update_favorite_count(listing_id)
        {:ok, :unfavorited}
    end
  end

  def user_favorited?(user_id, listing_id) do
    Favorite
    |> where([f], f.user_id == ^user_id and f.listing_id == ^listing_id)
    |> Repo.exists?()
  end

  def list_user_favorites(user_id) do
    Favorite
    |> where([f], f.user_id == ^user_id)
    |> join(:inner, [f], l in assoc(f, :listing))
    |> preload([f, l], listing: {l, [:category, :images, :user]})
    |> order_by([f], desc: f.inserted_at)
    |> Repo.all()
  end

  defp update_favorite_count(listing_id) do
    count =
      Favorite
      |> where([f], f.listing_id == ^listing_id)
      |> Repo.aggregate(:count)

    Listing
    |> where(id: ^listing_id)
    |> Repo.update_all(set: [favorite_count: count])
  end

  ## Search

  def search_listings(query_string, opts \\ []) do
    opts
    |> Keyword.put(:search, query_string)
    |> then(&list_listings/1)
  end
end
