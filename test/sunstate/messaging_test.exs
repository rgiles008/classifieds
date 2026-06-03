defmodule Sunstate.MessagingTest do
  use Sunstate.DataCase, async: true

  alias Sunstate.Messaging

  import Sunstate.AccountsFixtures
  import Sunstate.ListingsFixtures
  # Fixtures available if needed
  # import Sunstate.MessagingFixtures

  describe "conversations" do
    test "get_or_create_conversation/2 creates a new conversation" do
      seller = user_fixture()
      buyer = user_fixture()
      listing = listing_fixture(%{user: seller})

      {:ok, conversation} = Messaging.get_or_create_conversation(listing, buyer)
      assert conversation.listing_id == listing.id
      assert conversation.buyer_id == buyer.id
      assert conversation.seller_id == seller.id
    end

    test "get_or_create_conversation/2 returns existing conversation" do
      seller = user_fixture()
      buyer = user_fixture()
      listing = listing_fixture(%{user: seller})

      {:ok, conv1} = Messaging.get_or_create_conversation(listing, buyer)
      {:ok, conv2} = Messaging.get_or_create_conversation(listing, buyer)
      assert conv1.id == conv2.id
    end

    test "list_user_conversations/1 returns conversations for a user" do
      seller = user_fixture()
      buyer = user_fixture()
      listing = listing_fixture(%{user: seller})

      {:ok, _conv} = Messaging.get_or_create_conversation(listing, buyer)

      # Both buyer and seller see the conversation
      assert length(Messaging.list_user_conversations(buyer.id)) == 1
      assert length(Messaging.list_user_conversations(seller.id)) == 1
    end

    test "user_in_conversation?/2 checks membership" do
      seller = user_fixture()
      buyer = user_fixture()
      outsider = user_fixture()
      listing = listing_fixture(%{user: seller})

      {:ok, conv} = Messaging.get_or_create_conversation(listing, buyer)

      assert Messaging.user_in_conversation?(buyer.id, conv.id)
      assert Messaging.user_in_conversation?(seller.id, conv.id)
      refute Messaging.user_in_conversation?(outsider.id, conv.id)
    end
  end

  describe "messages" do
    setup do
      seller = user_fixture()
      buyer = user_fixture()
      listing = listing_fixture(%{user: seller})
      {:ok, conversation} = Messaging.get_or_create_conversation(listing, buyer)
      %{conversation: conversation, buyer: buyer, seller: seller}
    end

    test "send_message/3 creates a message", %{conversation: conv, buyer: buyer} do
      {:ok, message} = Messaging.send_message(conv, buyer, "Hello!")
      assert message.body == "Hello!"
      assert message.sender_id == buyer.id
      assert message.conversation_id == conv.id
    end

    test "send_message/3 updates conversation last_message_at", %{conversation: conv, buyer: buyer} do
      {:ok, _message} = Messaging.send_message(conv, buyer, "Hello!")
      updated = Repo.get!(Sunstate.Messaging.Conversation, conv.id)
      assert updated.last_message_at
    end

    test "send_message/3 validates body is not empty", %{conversation: conv, buyer: buyer} do
      {:error, changeset} = Messaging.send_message(conv, buyer, "")
      assert %{body: ["can't be blank"]} = errors_on(changeset)
    end

    test "list_messages/1 returns messages in order", %{conversation: conv, buyer: buyer, seller: seller} do
      {:ok, _m1} = Messaging.send_message(conv, buyer, "Hi there!")
      {:ok, _m2} = Messaging.send_message(conv, seller, "Hello! How can I help?")
      {:ok, _m3} = Messaging.send_message(conv, buyer, "Is this still available?")

      messages = Messaging.list_messages(conv.id)
      assert length(messages) == 3
      assert Enum.at(messages, 0).body == "Hi there!"
      assert Enum.at(messages, 2).body == "Is this still available?"
    end

    test "mark_messages_read/2 marks other user's messages as read", %{
      conversation: conv,
      buyer: buyer,
      seller: seller
    } do
      {:ok, _} = Messaging.send_message(conv, buyer, "Hello!")
      {:ok, _} = Messaging.send_message(conv, buyer, "Are you there?")

      # Seller marks buyer's messages as read
      {count, _} = Messaging.mark_messages_read(conv.id, seller.id)
      assert count == 2

      # Verify messages are marked
      messages = Messaging.list_messages(conv.id)
      assert Enum.all?(messages, &(&1.read_at != nil))
    end

    test "unread_count/1 counts unread messages for a user", %{
      conversation: conv,
      buyer: buyer,
      seller: seller
    } do
      {:ok, _} = Messaging.send_message(conv, buyer, "Hello!")
      {:ok, _} = Messaging.send_message(conv, buyer, "Anyone?")

      assert Messaging.unread_count(seller.id) == 2
      assert Messaging.unread_count(buyer.id) == 0

      Messaging.mark_messages_read(conv.id, seller.id)
      assert Messaging.unread_count(seller.id) == 0
    end
  end

  describe "pubsub" do
    test "send_message/3 broadcasts to conversation topic" do
      seller = user_fixture()
      buyer = user_fixture()
      listing = listing_fixture(%{user: seller})
      {:ok, conv} = Messaging.get_or_create_conversation(listing, buyer)

      Messaging.subscribe_conversation(conv.id)
      {:ok, message} = Messaging.send_message(conv, buyer, "Hello!")

      assert_receive {:new_message, received}
      assert received.id == message.id
      assert received.body == "Hello!"
    end
  end
end
