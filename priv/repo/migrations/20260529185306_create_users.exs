defmodule Sunstate.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    create table(:users) do
      # Basic info
      add :email, :citext, null: false
      add :hashed_password, :string, null: false
      add :display_name, :string
      add :phone, :string
      add :phone_verified, :boolean, default: false
      add :avatar_url, :string

      # Email verification
      add :confirmed_at, :utc_datetime

      # Two-Factor Authentication (TOTP)
      add :totp_secret, :binary
      add :totp_enabled, :boolean, default: false
      add :backup_codes, {:array, :string}

      # Stripe Identity Verification
      add :stripe_identity_session_id, :string
      add :stripe_identity_status, :string
      add :identity_verified_at, :utc_datetime

      # Profile settings
      add :contact_preferences, :map, default: %{}
      add :notification_settings, :map, default: %{}

      # Soft delete / deactivation
      add :deactivated_at, :utc_datetime

      timestamps()
    end

    create unique_index(:users, [:email])
    create index(:users, [:stripe_identity_status])
    create index(:users, [:confirmed_at])
  end
end
