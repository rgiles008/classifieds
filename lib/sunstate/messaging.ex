defmodule Sunstate.Messaging do
  @moduledoc """
  The Messaging context for conversations between buyers and sellers.
  """

  import Ecto.Query
  alias Sunstate.Repo
  alias Sunstate.Messaging.{Conversation, Message}

  ## Conversations

  def get_or_create_conversation(listing, buyer) do
    case Repo.get_by(Conversation, listing_id: listing.id, buyer_id: buyer.id) do
      nil ->
        %Conversation{
          listing_id: listing.id,
          buyer_id: buyer.id,
          seller_id: listing.user_id
        }
        |> Conversation.changeset(%{})
        |> Repo.insert()

      conversation ->
        {:ok, conversation}
    end
  end

  def get_conversation!(id) do
    Conversation
    |> preload([:listing, :buyer, :seller])
    |> Repo.get!(id)
  end

  def list_user_conversations(user_id) do
    Conversation
    |> where([c], c.buyer_id == ^user_id or c.seller_id == ^user_id)
    |> order_by([c], desc: c.last_message_at)
    |> preload([:listing, :buyer, :seller])
    |> Repo.all()
  end

  def user_in_conversation?(user_id, conversation_id) do
    Conversation
    |> where([c], c.id == ^conversation_id)
    |> where([c], c.buyer_id == ^user_id or c.seller_id == ^user_id)
    |> Repo.exists?()
  end

  def unread_count(user_id) do
    Message
    |> join(:inner, [m], c in assoc(m, :conversation))
    |> where([m, c], c.buyer_id == ^user_id or c.seller_id == ^user_id)
    |> where([m, c], m.sender_id != ^user_id)
    |> where([m], is_nil(m.read_at))
    |> Repo.aggregate(:count)
  end

  ## Messages

  def list_messages(conversation_id) do
    Message
    |> where([m], m.conversation_id == ^conversation_id)
    |> order_by([m], asc: m.inserted_at)
    |> preload(:sender)
    |> Repo.all()
  end

  def send_message(conversation, sender, body) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:message,
      %Message{conversation_id: conversation.id, sender_id: sender.id}
      |> Message.changeset(%{body: body})
    )
    |> Ecto.Multi.update(:conversation,
      Ecto.Changeset.change(conversation, last_message_at: now)
    )
    |> Repo.transaction()
    |> case do
      {:ok, %{message: message}} ->
        message = Repo.preload(message, :sender)

        Phoenix.PubSub.broadcast(
          Sunstate.PubSub,
          "conversation:#{conversation.id}",
          {:new_message, message}
        )

        {:ok, message}

      {:error, :message, changeset, _} ->
        {:error, changeset}
    end
  end

  def mark_messages_read(conversation_id, user_id) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    Message
    |> where([m], m.conversation_id == ^conversation_id)
    |> where([m], m.sender_id != ^user_id)
    |> where([m], is_nil(m.read_at))
    |> Repo.update_all(set: [read_at: now])
  end

  def subscribe_conversation(conversation_id) do
    Phoenix.PubSub.subscribe(Sunstate.PubSub, "conversation:#{conversation_id}")
  end
end
