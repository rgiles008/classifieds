defmodule Sunstate.Messaging.Message do
  use Ecto.Schema
  import Ecto.Changeset

  schema "messages" do
    field :body, :string
    field :read_at, :utc_datetime

    belongs_to :conversation, Sunstate.Messaging.Conversation
    belongs_to :sender, Sunstate.Accounts.User

    timestamps()
  end

  def changeset(message, attrs) do
    message
    |> cast(attrs, [:body])
    |> validate_required([:body, :conversation_id, :sender_id])
    |> validate_length(:body, min: 1, max: 5000)
    |> foreign_key_constraint(:conversation_id)
    |> foreign_key_constraint(:sender_id)
  end
end
