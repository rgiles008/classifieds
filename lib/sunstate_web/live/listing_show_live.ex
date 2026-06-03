defmodule SunstateWeb.ListingShowLive do
  use SunstateWeb, :live_view

  alias Sunstate.Listings

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user}>
      <div class="max-w-4xl mx-auto">
        <%!-- Breadcrumb --%>
        <div class="text-sm breadcrumbs mb-4">
          <ul>
            <li><.link navigate={~p"/listings"}>Listings</.link></li>
            <li :if={@listing.category}>
              <.link navigate={~p"/listings?#{%{category: @listing.category.slug}}"}>{@listing.category.name}</.link>
            </li>
            <li class="text-base-content/60">{@listing.title}</li>
          </ul>
        </div>

        <div class="flex flex-col lg:flex-row gap-8">
          <%!-- Images --%>
          <div class="lg:w-1/2">
            <div class="bg-base-200 rounded-lg aspect-square flex items-center justify-center overflow-hidden">
              <%= if @primary_image do %>
                <img src={@primary_image} alt={@listing.title} class="w-full h-full object-cover" />
              <% else %>
                <.icon name="hero-photo" class="size-24 text-base-content/20" />
              <% end %>
            </div>
            <div :if={length(@listing.images) > 1} class="flex gap-2 mt-2 overflow-x-auto">
              <div
                :for={image <- @listing.images}
                class="w-20 h-20 flex-shrink-0 bg-base-200 rounded overflow-hidden cursor-pointer"
              >
                <img
                  src={~p"/uploads/#{image.storage_key}"}
                  alt="Thumbnail"
                  class="w-full h-full object-cover"
                />
              </div>
            </div>
          </div>

          <%!-- Details --%>
          <div class="lg:w-1/2 flex flex-col gap-4">
            <div class="flex items-start justify-between">
              <div>
                <h1 id="listing-title" class="text-2xl font-bold">{@listing.title}</h1>
                <p class="text-2xl font-bold text-primary mt-1">{format_price(@listing)}</p>
              </div>
              <button
                :if={@current_user}
                id="favorite-btn"
                phx-click="toggle_favorite"
                class={["btn btn-ghost btn-circle", @favorited? && "text-error"]}
              >
                <.icon name={if @favorited?, do: "hero-heart-solid", else: "hero-heart"} class="size-6" />
              </button>
            </div>

            <div class="flex flex-wrap gap-2">
              <span :if={@listing.condition} class="badge badge-outline">
                {humanize_condition(@listing.condition)}
              </span>
              <span :if={@listing.category} class="badge badge-outline">
                {@listing.category.name}
              </span>
              <span class="badge badge-outline">
                <.icon name="hero-map-pin-micro" class="size-3 mr-1" />
                {@listing.city || @listing.zip_code}, {@listing.state}
              </span>
            </div>

            <div class="divider my-0"></div>

            <div>
              <h3 class="font-semibold mb-2">Description</h3>
              <p id="listing-description" class="whitespace-pre-wrap text-base-content/80">{@listing.description}</p>
            </div>

            <div class="divider my-0"></div>

            <%!-- Seller info --%>
            <div class="flex items-center gap-3">
              <div class="avatar placeholder">
                <div class="bg-neutral text-neutral-content w-10 rounded-full">
                  <span>{String.first(@listing.user.display_name || @listing.user.email) |> String.upcase()}</span>
                </div>
              </div>
              <div>
                <p class="font-medium">{@listing.user.display_name || "Seller"}</p>
                <p class="text-sm text-base-content/60">
                  Member since {Calendar.strftime(@listing.user.inserted_at, "%B %Y")}
                </p>
              </div>
            </div>

            <div class="flex gap-2 mt-2">
              <.link :if={@is_owner} navigate={~p"/listings/#{@listing.id}/edit"} class="btn btn-outline flex-1">
                <.icon name="hero-pencil" class="size-4" /> Edit
              </.link>
              <button :if={@is_owner} phx-click="mark_sold" class="btn btn-primary flex-1"
                data-confirm="Mark this listing as sold?">
                <.icon name="hero-check-circle" class="size-4" /> Mark as Sold
              </button>
              <button :if={!@is_owner && @current_user} phx-click="contact_seller" class="btn btn-primary flex-1">
                <.icon name="hero-chat-bubble-left-right" class="size-4" /> Contact Seller
              </button>
              <.link :if={!@current_user} navigate={~p"/users/log_in"} class="btn btn-primary flex-1">
                Sign in to contact seller
              </.link>
            </div>

            <div class="text-xs text-base-content/40 mt-2">
              <span>{@listing.view_count} views</span>
              <span class="mx-2">&middot;</span>
              <span>{@listing.favorite_count} favorites</span>
              <span class="mx-2">&middot;</span>
              <span>Posted {Calendar.strftime(@listing.inserted_at, "%b %d, %Y")}</span>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    listing = Listings.get_listing!(id)

    # Increment view count (don't count owner's views)
    is_owner = socket.assigns.current_user && socket.assigns.current_user.id == listing.user_id

    unless is_owner do
      Listings.increment_view_count(listing)
    end

    favorited? =
      if socket.assigns.current_user do
        Listings.user_favorited?(socket.assigns.current_user.id, listing.id)
      else
        false
      end

    primary_image =
      case Enum.find(listing.images, & &1.is_primary) || List.first(listing.images) do
        %{storage_key: key} -> "/uploads/#{key}"
        _ -> nil
      end

    {:ok,
     socket
     |> assign(:listing, listing)
     |> assign(:is_owner, is_owner)
     |> assign(:favorited?, favorited?)
     |> assign(:primary_image, primary_image)
     |> assign(:page_title, listing.title)}
  end

  @impl true
  def handle_event("toggle_favorite", _params, socket) do
    user = socket.assigns.current_user
    listing = socket.assigns.listing

    case Listings.toggle_favorite(user.id, listing.id) do
      {:ok, :favorited, _} ->
        listing = %{listing | favorite_count: listing.favorite_count + 1}
        {:noreply, socket |> assign(:favorited?, true) |> assign(:listing, listing)}

      {:ok, :unfavorited} ->
        listing = %{listing | favorite_count: max(listing.favorite_count - 1, 0)}
        {:noreply, socket |> assign(:favorited?, false) |> assign(:listing, listing)}

      _ ->
        {:noreply, put_flash(socket, :error, "Something went wrong")}
    end
  end

  def handle_event("contact_seller", _params, socket) do
    listing = socket.assigns.listing
    user = socket.assigns.current_user

    case Sunstate.Messaging.get_or_create_conversation(listing, user) do
      {:ok, conversation} ->
        {:noreply, push_navigate(socket, to: ~p"/conversations/#{conversation.id}")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not start conversation")}
    end
  end

  def handle_event("mark_sold", _params, socket) do
    case Listings.mark_listing_sold(socket.assigns.listing) do
      {:ok, listing} ->
        {:noreply,
         socket
         |> assign(:listing, Listings.get_listing!(listing.id))
         |> put_flash(:info, "Listing marked as sold!")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not update listing")}
    end
  end

  defp format_price(listing) do
    case listing.price_type do
      "free" -> "Free"
      "contact" -> "Contact for price"
      _ ->
        if listing.price do
          "$#{Decimal.round(listing.price, 2)}"
        else
          "Contact for price"
        end
    end
  end

  defp humanize_condition(condition) do
    case condition do
      "new" -> "New"
      "like_new" -> "Like New"
      "good" -> "Good"
      "fair" -> "Fair"
      "poor" -> "Poor"
      _ -> condition
    end
  end
end
