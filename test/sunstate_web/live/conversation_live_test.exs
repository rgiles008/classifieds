defmodule SunstateWeb.ConversationLiveTest do
  use SunstateWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Sunstate.AccountsFixtures
  import Sunstate.ListingsFixtures

  alias Sunstate.Messaging

  describe "Inbox page" do
    setup :register_and_log_in_user

    test "renders inbox", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/inbox")
      assert html =~ "Messages"
    end

    test "shows user's conversations", %{conn: conn, user: user} do
      seller = user_fixture()
      listing = listing_fixture(%{user: seller, title: "Cool Item Chat"})
      {:ok, conv} = Messaging.get_or_create_conversation(listing, user)
      {:ok, _} = Messaging.send_message(conv, user, "Hi!")

      {:ok, _lv, html} = live(conn, ~p"/inbox")
      assert html =~ "Cool Item Chat"
    end
  end

  describe "Conversation page" do
    setup do
      buyer = user_fixture()
      seller = user_fixture()
      listing = listing_fixture(%{user: seller, title: "Test Chat Item"})
      {:ok, conversation} = Messaging.get_or_create_conversation(listing, buyer)

      %{buyer: buyer, seller: seller, listing: listing, conversation: conversation}
    end

    test "renders conversation", %{conn: conn, buyer: buyer, conversation: conversation} do
      conn = log_in_user(conn, buyer)
      {:ok, _lv, html} = live(conn, ~p"/conversations/#{conversation.id}")
      assert html =~ "Test Chat Item"
    end

    test "displays messages", %{conn: conn, buyer: buyer, seller: seller, conversation: conversation} do
      {:ok, _} = Messaging.send_message(conversation, buyer, "Is this available?")
      {:ok, _} = Messaging.send_message(conversation, seller, "Yes it is!")

      conn = log_in_user(conn, buyer)
      {:ok, _lv, html} = live(conn, ~p"/conversations/#{conversation.id}")
      assert html =~ "Is this available?"
      assert html =~ "Yes it is!"
    end

    test "sends a message", %{conn: conn, buyer: buyer, conversation: conversation} do
      conn = log_in_user(conn, buyer)
      {:ok, lv, _html} = live(conn, ~p"/conversations/#{conversation.id}")

      lv
      |> form("#message-form", %{"body" => "Hello seller!"})
      |> render_submit()

      # Message appears via PubSub
      html = render(lv)
      assert html =~ "Hello seller!"
    end

    test "denies access to non-participants", %{conn: conn, conversation: conversation} do
      outsider = user_fixture()
      conn = log_in_user(conn, outsider)

      assert_raise Ecto.NoResultsError, fn ->
        live(conn, ~p"/conversations/#{conversation.id}")
      end
    end

    test "receives real-time messages via PubSub", %{
      conn: conn,
      buyer: buyer,
      seller: seller,
      conversation: conversation
    } do
      conn = log_in_user(conn, buyer)
      {:ok, lv, _html} = live(conn, ~p"/conversations/#{conversation.id}")

      # Seller sends a message (simulates another user)
      {:ok, _msg} = Messaging.send_message(conversation, seller, "Just shipped it!")

      html = render(lv)
      assert html =~ "Just shipped it!"
    end
  end

  describe "Contact seller flow" do
    setup :register_and_log_in_user

    test "contact seller creates conversation and redirects", %{conn: conn, user: _buyer} do
      seller = user_fixture()
      listing = listing_fixture(%{user: seller, title: "Item To Buy"})

      {:ok, lv, _html} = live(conn, ~p"/listings/#{listing.id}")
      lv |> element("button", "Contact Seller") |> render_click()

      {path, _flash} = assert_redirect(lv)
      assert path =~ ~r"/conversations/\d+"
    end
  end
end
