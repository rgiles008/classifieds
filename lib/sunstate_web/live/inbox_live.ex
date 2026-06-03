defmodule SunstateWeb.InboxLive do
  use SunstateWeb, :live_view

  alias Sunstate.Messaging

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user}>
      <.header class="mb-6">Messages</.header>

      <div id="conversations" phx-update="stream">
        <div id="conversations-empty" class="hidden only:block text-center py-12 text-base-content/50">
          <.icon name="hero-chat-bubble-left-right" class="size-12 mx-auto mb-4" />
          <p class="text-lg">No messages yet</p>
          <p class="text-sm mt-2">
            When you contact a seller or someone contacts you, conversations will appear here.
          </p>
        </div>
        <.link
          :for={{id, conversation} <- @streams.conversations}
          id={id}
          navigate={~p"/conversations/#{conversation.id}"}
          class="flex items-center gap-4 p-4 border-b border-base-200 hover:bg-base-200/50 transition-colors"
        >
          <div class="avatar placeholder">
            <div class="bg-neutral text-neutral-content w-10 rounded-full">
              <span class="text-xs">
                {other_user(conversation, @current_user) |> display_initial()}
              </span>
            </div>
          </div>
          <div class="flex-1 min-w-0">
            <p class="font-medium line-clamp-1">{conversation.listing.title}</p>
            <p class="text-sm text-base-content/60 line-clamp-1">
              with {other_user(conversation, @current_user) |> display_name()}
            </p>
          </div>
          <div :if={conversation.last_message_at} class="text-xs text-base-content/40 flex-shrink-0">
            {format_time(conversation.last_message_at)}
          </div>
        </.link>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    conversations = Messaging.list_user_conversations(socket.assigns.current_user.id)
    {:ok, stream(socket, :conversations, conversations)}
  end

  defp other_user(conversation, current_user) do
    if conversation.buyer_id == current_user.id do
      conversation.seller
    else
      conversation.buyer
    end
  end

  defp display_name(user), do: user.display_name || user.email
  defp display_initial(user), do: String.first(user.display_name || user.email) |> String.upcase()

  defp format_time(datetime) do
    Calendar.strftime(datetime, "%b %d")
  end
end
