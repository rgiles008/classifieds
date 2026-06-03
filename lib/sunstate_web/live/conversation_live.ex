defmodule SunstateWeb.ConversationLive do
  use SunstateWeb, :live_view

  alias Sunstate.Messaging

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user}>
      <div class="max-w-3xl mx-auto flex flex-col h-[calc(100vh-12rem)]">
        <%!-- Header --%>
        <div class="flex items-center gap-4 pb-4 border-b border-base-200">
          <.link navigate={~p"/inbox"} class="btn btn-ghost btn-sm btn-circle">
            <.icon name="hero-arrow-left" class="size-5" />
          </.link>
          <div class="flex-1 min-w-0">
            <.link navigate={~p"/listings/#{@conversation.listing.id}"} class="font-semibold hover:text-primary line-clamp-1">
              {@conversation.listing.title}
            </.link>
            <p class="text-sm text-base-content/60">
              with {display_name(@other_user)}
            </p>
          </div>
        </div>

        <%!-- Messages --%>
        <div id="messages-container" class="flex-1 overflow-y-auto py-4 space-y-3" phx-hook="ScrollBottom">
          <div id="messages" phx-update="stream">
            <div id="messages-empty" class="hidden only:block text-center py-8 text-base-content/50">
              <p>No messages yet. Send one to start the conversation!</p>
            </div>
            <div
              :for={{id, message} <- @streams.messages}
              id={id}
              class={[
                "chat",
                if(message.sender_id == @current_user.id, do: "chat-end", else: "chat-start")
              ]}
            >
              <div class="chat-header text-xs text-base-content/50 mb-1">
                {display_name(message.sender)}
                <time class="ml-2">{Calendar.strftime(message.inserted_at, "%I:%M %p")}</time>
              </div>
              <div class={[
                "chat-bubble",
                if(message.sender_id == @current_user.id, do: "chat-bubble-primary", else: "")
              ]}>
                {message.body}
              </div>
            </div>
          </div>
        </div>

        <%!-- Message Input --%>
        <div class="border-t border-base-200 pt-4">
          <form id="message-form" phx-submit="send_message" class="flex gap-2">
            <input
              type="text"
              name="body"
              value=""
              placeholder="Type a message..."
              class="input input-bordered flex-1"
              autocomplete="off"
              required
            />
            <button type="submit" class="btn btn-primary" phx-disable-with="Sending...">
              <.icon name="hero-paper-airplane" class="size-5" />
            </button>
          </form>
        </div>
      </div>
    </Layouts.app>

    <script :type={Phoenix.LiveView.ColocatedHook} name=".ScrollBottom">
      export default {
        mounted() {
          this.el.scrollTop = this.el.scrollHeight
        },
        updated() {
          this.el.scrollTop = this.el.scrollHeight
        }
      }
    </script>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    conversation = Messaging.get_conversation!(id)
    user = socket.assigns.current_user

    unless conversation.buyer_id == user.id || conversation.seller_id == user.id do
      raise Ecto.NoResultsError, queryable: Sunstate.Messaging.Conversation
    end

    messages = Messaging.list_messages(conversation.id)
    Messaging.mark_messages_read(conversation.id, user.id)

    if connected?(socket) do
      Messaging.subscribe_conversation(conversation.id)
    end

    other_user =
      if conversation.buyer_id == user.id,
        do: conversation.seller,
        else: conversation.buyer

    {:ok,
     socket
     |> assign(:conversation, conversation)
     |> assign(:other_user, other_user)
     |> assign(:page_title, "Chat - #{conversation.listing.title}")
     |> stream(:messages, messages)}
  end

  @impl true
  def handle_event("send_message", %{"body" => body}, socket) do
    body = String.trim(body)

    if body != "" do
      case Messaging.send_message(socket.assigns.conversation, socket.assigns.current_user, body) do
        {:ok, _message} ->
          {:noreply, socket}

        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, "Could not send message")}
      end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:new_message, message}, socket) do
    # Mark as read if we're the recipient
    if message.sender_id != socket.assigns.current_user.id do
      Messaging.mark_messages_read(socket.assigns.conversation.id, socket.assigns.current_user.id)
    end

    {:noreply, stream_insert(socket, :messages, message)}
  end

  defp display_name(user), do: user.display_name || user.email
end
