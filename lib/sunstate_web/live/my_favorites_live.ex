defmodule SunstateWeb.MyFavoritesLive do
  use SunstateWeb, :live_view

  alias Sunstate.Listings

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user}>
      <.header class="mb-6">My Favorites</.header>

      <div id="favorites" phx-update="stream" class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
        <div id="favorites-empty" class="hidden only:block col-span-full text-center py-12 text-base-content/50">
          <.icon name="hero-heart" class="size-12 mx-auto mb-4" />
          <p class="text-lg">No favorites yet</p>
          <p class="text-sm mt-2">
            <.link navigate={~p"/listings"} class="text-primary hover:underline">Browse listings</.link>
            to find items you like.
          </p>
        </div>
        <div
          :for={{id, favorite} <- @streams.favorites}
          id={id}
          class="card bg-base-100 shadow-sm border border-base-200"
        >
          <figure class="h-40 bg-base-200 flex items-center justify-center">
            <.icon name="hero-photo" class="size-12 text-base-content/20" />
          </figure>
          <div class="card-body p-4">
            <.link navigate={~p"/listings/#{favorite.listing.id}"} class="card-title text-base hover:text-primary line-clamp-1">
              {favorite.listing.title}
            </.link>
            <p class="text-lg font-bold text-primary">{format_price(favorite.listing)}</p>
            <div class="flex items-center justify-between mt-2">
              <span class="text-sm text-base-content/60">
                {favorite.listing.city || favorite.listing.zip_code}, {favorite.listing.state}
              </span>
              <button
                phx-click="unfavorite"
                phx-value-id={favorite.listing.id}
                phx-value-fav-id={favorite.id}
                class="btn btn-ghost btn-xs text-error"
              >
                <.icon name="hero-heart-solid" class="size-4" /> Remove
              </button>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    favorites = Listings.list_user_favorites(socket.assigns.current_user.id)
    {:ok, stream(socket, :favorites, favorites)}
  end

  @impl true
  def handle_event("unfavorite", %{"id" => listing_id, "fav-id" => _fav_id}, socket) do
    user = socket.assigns.current_user

    case Listings.toggle_favorite(user.id, String.to_integer(listing_id)) do
      {:ok, :unfavorited} ->
        # Reload favorites to reset stream
        favorites = Listings.list_user_favorites(user.id)
        {:noreply, stream(socket, :favorites, favorites, reset: true)}

      _ ->
        {:noreply, put_flash(socket, :error, "Something went wrong")}
    end
  end

  defp format_price(listing) do
    case listing.price_type do
      "free" -> "Free"
      "contact" -> "Contact"
      _ ->
        if listing.price do
          "$#{Decimal.round(listing.price, 2)}"
        else
          "Contact"
        end
    end
  end
end
