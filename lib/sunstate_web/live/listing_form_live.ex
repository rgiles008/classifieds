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

          <%!-- Image Upload --%>
          <div class="fieldset mb-2">
            <label class="label mb-1">Photos (up to 6)</label>
            <div
              class="border-2 border-dashed border-base-300 rounded-lg p-6 text-center cursor-pointer hover:border-primary transition-colors"
              phx-drop-target={@uploads.images.ref}
            >
              <.icon name="hero-photo" class="size-8 mx-auto mb-2 text-base-content/40" />
              <p class="text-sm text-base-content/60">Drag & drop images here or</p>
              <label class="btn btn-sm btn-outline mt-2 cursor-pointer">
                Browse Files
                <.live_file_input upload={@uploads.images} class="hidden" />
              </label>
            </div>

            <%!-- Upload previews --%>
            <div :if={@uploads.images.entries != []} class="flex flex-wrap gap-3 mt-4">
              <div :for={entry <- @uploads.images.entries} class="relative group">
                <.live_img_preview entry={entry} class="w-24 h-24 object-cover rounded-lg" />
                <button
                  type="button"
                  phx-click="cancel_upload"
                  phx-value-ref={entry.ref}
                  class="absolute -top-2 -right-2 btn btn-circle btn-xs btn-error opacity-0 group-hover:opacity-100 transition-opacity"
                  aria-label="Remove"
                >
                  <.icon name="hero-x-mark" class="size-3" />
                </button>
                <div :if={entry.progress > 0 && entry.progress < 100}
                  class="absolute bottom-0 left-0 right-0 h-1 bg-base-200 rounded-b-lg overflow-hidden">
                  <div class="h-full bg-primary transition-all" style={"width: #{entry.progress}%"}></div>
                </div>
                <p :for={err <- upload_errors(@uploads.images, entry)} class="text-xs text-error mt-1">
                  {upload_error_to_string(err)}
                </p>
              </div>
            </div>

            <%!-- Existing images (edit mode) --%>
            <div :if={@live_action == :edit && @listing.images != []} class="flex flex-wrap gap-3 mt-4">
              <div :for={image <- @listing.images} class="relative group">
                <img src={~p"/uploads/#{image.storage_key}"} class="w-24 h-24 object-cover rounded-lg" alt="Listing image" />
                <button
                  type="button"
                  phx-click="delete_image"
                  phx-value-id={image.id}
                  class="absolute -top-2 -right-2 btn btn-circle btn-xs btn-error opacity-0 group-hover:opacity-100 transition-opacity"
                  aria-label="Remove"
                >
                  <.icon name="hero-x-mark" class="size-3" />
                </button>
              </div>
            </div>
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

    {:ok,
     socket
     |> assign(:categories, categories)
     |> allow_upload(:images,
       accept: ~w(.jpg .jpeg .png .webp),
       max_entries: 6,
       max_file_size: 10_000_000
     )}
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

  def handle_event("cancel_upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :images, ref)}
  end

  def handle_event("delete_image", %{"id" => id}, socket) do
    image = Sunstate.Repo.get!(Sunstate.Listings.ListingImage, String.to_integer(id))

    if image.listing_id == socket.assigns.listing.id do
      # Delete the file
      path = Path.join(["priv/static/uploads", image.storage_key])
      File.rm(path)

      Listings.delete_listing_image(image)
      listing = Listings.get_listing!(socket.assigns.listing.id)
      {:noreply, assign(socket, :listing, listing)}
    else
      {:noreply, socket}
    end
  end

  defp save_listing(socket, :new, listing_params) do
    case Listings.create_listing(socket.assigns.current_user, listing_params) do
      {:ok, listing} ->
        save_uploaded_images(socket, listing)

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
        save_uploaded_images(socket, listing)

        {:noreply,
         socket
         |> put_flash(:info, "Listing updated successfully!")
         |> push_navigate(to: ~p"/listings/#{listing.id}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp save_uploaded_images(socket, listing) do
    listing = Sunstate.Repo.preload(listing, :images)
    existing_count = length(listing.images)

    consume_uploaded_entries(socket, :images, fn %{path: path}, entry ->
      ext = Path.extname(entry.client_name)
      filename = "#{listing.id}_#{System.unique_integer([:positive])}#{ext}"
      dest = Path.join(["priv/static/uploads", filename])

      File.cp!(path, dest)
      {:ok, filename}
    end)
    |> Enum.with_index(existing_count)
    |> Enum.each(fn {filename, position} ->
      Listings.add_listing_image(listing, %{
        storage_key: filename,
        position: position,
        is_primary: position == 0
      })
    end)
  end

  defp upload_error_to_string(:too_large), do: "File is too large (max 10MB)"
  defp upload_error_to_string(:not_accepted), do: "Invalid file type (JPG, PNG, WebP only)"
  defp upload_error_to_string(:too_many_files), do: "Too many files (max 6)"
  defp upload_error_to_string(_), do: "Upload error"
end
