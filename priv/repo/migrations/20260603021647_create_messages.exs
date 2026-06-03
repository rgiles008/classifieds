defmodule Sunstate.Repo.Migrations.CreateMessages do
  use Ecto.Migration

  def change do
    create table(:messages) do
      add :body, :text, null: false
      add :read_at, :utc_datetime
      add :conversation_id, references(:conversations, on_delete: :delete_all), null: false
      add :sender_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:messages, [:conversation_id])
    create index(:messages, [:sender_id])
  end
end
