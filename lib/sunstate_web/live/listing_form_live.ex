defmodule SunstateWeb.ListingFormLive do
  use SunstateWeb, :live_view

  alias Sunstate.Listings
  alias Sunstate.Listings.Listing

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user}>
      <div class="max-w-2xl mx-auto">
        <.header class="text-center">
          {@page_title}
          <:subtitle>
            {if @live_action == :new, do: "Create a new listing", else: "Update your listing"}
          </:subtitle>
        </.header>

        <.simple_form
          for={@form}
          id="listing-form"
          phx-change="validate"
          phx-submit="save"
        >
          <.input field={@form[:title]} type="text" label="Title" required
            placeholder="What are you selling?" />

          <.input field={@form[:description]} type="textarea" label="Description" required
            placeholder="Describe your item in detail..." />

          <div class="grid grid-cols-2 gap-4">
            <.input field={@form[:price]} type="number" label="Price" step="0.01" min="0"
              placeholder="0.00" />
            <.input field={@form[:price_type]} type="select" label="Price Type"
              options={[{"Fixed Price", "fixed"}, {"Negotiable", "negotiable"}, {"Free", "free"}, {"Contact for Price", "contact"}]} />
          </div>

          <div class="grid grid-cols-2 gap-4">
            <.input field={@form[:condition]} type="select" label="Condition"
              prompt="Select condition..."
              options={[{"New", "new"}, {"Like New", "like_new"}, {"Good", "good"}, {"Fair", "fair"}, {"Poor", "poor"}]} />
            <.input field={@form[:category_id]} type="select" label="Category"
              prompt="Select a category..."
              options={Enum.map(@categories, &{&1.name, &1.id})} />
          </div>

          <div class="grid grid-cols-2 gap-4">
            <.input field={@form[:zip_code]} type="text" label="Zip Code" required
              placeholder="32801" maxlength="5" />
            <.input field={@form[:city]} type="text" label="City"
              placeholder="Orlando" />
          </div>

          <:actions>
            <.link navigate={if @live_action == :edit, do: ~p"/listings/#{@listing.id}", else: ~p"/listings"}
              class="btn btn-ghost">
              Cancel
            </.link>
            <.button phx-disable-with="Saving..." variant="primary">
              {if @live_action == :new, do: "Post Listing", else: "Update Listing"}
            </.button>
          </:actions>
        </.simple_form>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    categories = Listings.list_categories()
    {:ok, assign(socket, :categories, categories)}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    listing = %Listing{}
    changeset = Listings.change_listing(listing)

    socket
    |> assign(:page_title, "New Listing")
    |> assign(:listing, listing)
    |> assign(:form, to_form(changeset))
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    listing = Listings.get_listing!(id)

    if listing.user_id != socket.assigns.current_user.id do
      socket
      |> put_flash(:error, "You can only edit your own listings.")
      |> push_navigate(to: ~p"/listings/#{listing.id}")
    else
      changeset = Listings.change_listing(listing)

      socket
      |> assign(:page_title, "Edit Listing")
      |> assign(:listing, listing)
      |> assign(:form, to_form(changeset))
    end
  end

  @impl true
  def handle_event("validate", %{"listing" => listing_params}, socket) do
    changeset =
      socket.assigns.listing
      |> Listings.change_listing(listing_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  def handle_event("save", %{"listing" => listing_params}, socket) do
    save_listing(socket, socket.assigns.live_action, listing_params)
  end

  defp save_listing(socket, :new, listing_params) do
    case Listings.create_listing(socket.assigns.current_user, listing_params) do
      {:ok, listing} ->
        {:noreply,
         socket
         |> put_flash(:info, "Listing created successfully!")
         |> push_navigate(to: ~p"/listings/#{listing.id}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp save_listing(socket, :edit, listing_params) do
    case Listings.update_listing(socket.assigns.listing, listing_params) do
      {:ok, listing} ->
        {:noreply,
         socket
         |> put_flash(:info, "Listing updated successfully!")
         |> push_navigate(to: ~p"/listings/#{listing.id}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end
end
