defmodule SunstateWeb.MyListingsLive do
  use SunstateWeb, :live_view

  alias Sunstate.Listings

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user}>
      <div class="flex items-center justify-between mb-6">
        <.header>My Listings</.header>
        <.link navigate={~p"/listings/new"} class="btn btn-primary btn-sm">
          <.icon name="hero-plus" class="size-4" /> New Listing
        </.link>
      </div>

      <div id="my-listings" phx-update="stream">
        <div id="my-listings-empty" class="hidden only:block text-center py-12 text-base-content/50">
          <.icon name="hero-rectangle-stack" class="size-12 mx-auto mb-4" />
          <p class="text-lg">You haven't posted any listings yet</p>
          <.link navigate={~p"/listings/new"} class="btn btn-primary mt-4">Post your first listing</.link>
        </div>
        <div
          :for={{id, listing} <- @streams.listings}
          id={id}
          class="flex items-center gap-4 p-4 border-b border-base-200"
        >
          <div class="w-16 h-16 bg-base-200 rounded flex items-center justify-center flex-shrink-0">
            <.icon name="hero-photo" class="size-8 text-base-content/20" />
          </div>
          <div class="flex-1 min-w-0">
            <.link navigate={~p"/listings/#{listing.id}"} class="font-medium hover:text-primary line-clamp-1">
              {listing.title}
            </.link>
            <div class="flex gap-3 text-sm text-base-content/60 mt-1">
              <span>{format_price(listing)}</span>
              <span>&middot;</span>
              <span class={[
                "badge badge-sm",
                listing.status == "active" && "badge-success",
                listing.status == "sold" && "badge-info",
                listing.status == "expired" && "badge-warning"
              ]}>
                {listing.status}
              </span>
              <span>&middot;</span>
              <span>{listing.view_count} views</span>
            </div>
          </div>
          <div class="flex gap-2 flex-shrink-0">
            <.link navigate={~p"/listings/#{listing.id}/edit"} class="btn btn-ghost btn-sm">
              <.icon name="hero-pencil" class="size-4" />
            </.link>
            <button phx-click="delete" phx-value-id={listing.id} class="btn btn-ghost btn-sm text-error"
              data-confirm="Are you sure you want to delete this listing?">
              <.icon name="hero-trash" class="size-4" />
            </button>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    listings = Listings.list_user_listings(user.id)

    {:ok, stream(socket, :listings, listings)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    listing = Listings.get_listing!(id)

    if listing.user_id == socket.assigns.current_user.id do
      {:ok, _} = Listings.delete_listing(listing)

      {:noreply,
       socket
       |> stream_delete(:listings, listing)
       |> put_flash(:info, "Listing deleted.")}
    else
      {:noreply, put_flash(socket, :error, "You can only delete your own listings.")}
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
