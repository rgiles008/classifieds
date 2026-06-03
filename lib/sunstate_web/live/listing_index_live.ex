defmodule SunstateWeb.ListingIndexLive do
  use SunstateWeb, :live_view

  alias Sunstate.Listings

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user}>
      <div class="flex flex-col gap-6">
        <%!-- Search & Filters --%>
        <div class="flex flex-col sm:flex-row gap-4">
          <form id="search-form" phx-submit="search" phx-change="search" class="flex-1">
            <.input
              name="q"
              type="text"
              value={@search_query}
              placeholder="Search listings..."
              class="w-full input input-bordered"
              phx-debounce="300"
            />
          </form>
          <div class="flex gap-2 flex-wrap">
            <.link
              :for={category <- @categories}
              patch={~p"/listings?#{%{category: category.slug}}"}
              class={[
                "btn btn-sm",
                if(@active_category && @active_category.id == category.id, do: "btn-primary", else: "btn-ghost")
              ]}
            >
              {category.name}
            </.link>
            <.link :if={@active_category} patch={~p"/listings"} class="btn btn-sm btn-ghost">
              Clear
            </.link>
          </div>
        </div>

        <%!-- Results count --%>
        <p class="text-sm text-base-content/70">
          {@listings_count} listing{if @listings_count != 1, do: "s"} found
        </p>

        <%!-- Listings Grid --%>
        <div id="listings" phx-update="stream" class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
          <div id="listings-empty" class="hidden only:block col-span-full text-center py-12 text-base-content/50">
            <.icon name="hero-magnifying-glass" class="size-12 mx-auto mb-4" />
            <p class="text-lg">No listings found</p>
            <p class="text-sm mt-2">Try adjusting your search or filters</p>
          </div>
          <.link
            :for={{id, listing} <- @streams.listings}
            id={id}
            navigate={~p"/listings/#{listing.id}"}
            class="card bg-base-100 shadow-sm hover:shadow-md transition-shadow border border-base-200"
          >
            <figure class="h-48 bg-base-200 flex items-center justify-center">
              <%= if primary_image(listing) do %>
                <img
                  src={primary_image(listing)}
                  alt={listing.title}
                  class="w-full h-full object-cover"
                />
              <% else %>
                <.icon name="hero-photo" class="size-16 text-base-content/20" />
              <% end %>
            </figure>
            <div class="card-body p-4">
              <h2 class="card-title text-base line-clamp-1">{listing.title}</h2>
              <p class="text-lg font-bold text-primary">
                {format_price(listing)}
              </p>
              <div class="flex items-center gap-2 text-sm text-base-content/60">
                <.icon name="hero-map-pin-micro" class="size-4" />
                <span>{listing.city || listing.zip_code}, {listing.state}</span>
              </div>
              <div :if={listing.condition} class="mt-1">
                <span class="badge badge-sm badge-ghost">{humanize_condition(listing.condition)}</span>
              </div>
            </div>
          </.link>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    categories = Listings.list_categories()

    {:ok,
     socket
     |> assign(:categories, categories)
     |> assign(:search_query, "")
     |> assign(:active_category, nil)
     |> assign(:listings_count, 0)
     |> stream(:listings, [])}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    category =
      if slug = params["category"] do
        Enum.find(socket.assigns.categories, &(&1.slug == slug))
      end

    search_query = params["q"] || ""

    filters =
      []
      |> then(fn f -> if category, do: [{:category_id, category.id} | f], else: f end)
      |> then(fn f -> if search_query != "", do: [{:search, search_query} | f], else: f end)

    listings = Listings.list_listings(filters)

    {:noreply,
     socket
     |> assign(:active_category, category)
     |> assign(:search_query, search_query)
     |> assign(:listings_count, length(listings))
     |> stream(:listings, listings, reset: true)}
  end

  @impl true
  def handle_event("search", %{"q" => query}, socket) do
    params =
      %{}
      |> then(fn p -> if query != "", do: Map.put(p, :q, query), else: p end)
      |> then(fn p ->
        if socket.assigns.active_category,
          do: Map.put(p, :category, socket.assigns.active_category.slug),
          else: p
      end)

    {:noreply, push_patch(socket, to: ~p"/listings?#{params}")}
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

  defp primary_image(listing) do
    case listing.images do
      [%{variants: %{"thumbnail" => url}} | _] -> url
      [%{storage_key: key} | _] -> key
      _ -> nil
    end
  end
end
