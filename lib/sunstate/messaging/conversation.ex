defmodule Sunstate.Messaging.Conversation do
  use Ecto.Schema
  import Ecto.Changeset

  schema "conversations" do
    field :last_message_at, :utc_datetime

    belongs_to :listing, Sunstate.Listings.Listing
    belongs_to :buyer, Sunstate.Accounts.User
    belongs_to :seller, Sunstate.Accounts.User
    has_many :messages, Sunstate.Messaging.Message

    timestamps()
  end

  def changeset(conversation, attrs) do
    conversation
    |> cast(attrs, [:last_message_at])
    |> validate_required([:listing_id, :buyer_id, :seller_id])
    |> unique_constraint([:listing_id, :buyer_id])
    |> foreign_key_constraint(:listing_id)
    |> foreign_key_constraint(:buyer_id)
    |> foreign_key_constraint(:seller_id)
  end
end
