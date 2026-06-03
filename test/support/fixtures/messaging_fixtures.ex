defmodule Sunstate.MessagingFixtures do
  @moduledoc """
  Test helpers for creating messaging entities.
  """

  alias Sunstate.AccountsFixtures
  alias Sunstate.ListingsFixtures

  def conversation_fixture(attrs \\ %{}) do
    buyer = attrs[:buyer] || AccountsFixtures.user_fixture()
    seller = attrs[:seller] || AccountsFixtures.user_fixture()
    listing = attrs[:listing] || ListingsFixtures.listing_fixture(%{user: seller})

    {:ok, conversation} =
      Sunstate.Messaging.get_or_create_conversation(
        %{listing | user_id: seller.id},
        buyer
      )

    conversation
  end
end
