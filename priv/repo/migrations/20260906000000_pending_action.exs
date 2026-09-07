defmodule Bonfire.Data.Identity.Repo.Migrations.PendingAction do
  use Ecto.Migration

  def change do
    create table(:bonfire_data_identity_pending_action, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :action, :text, null: false
      add :account_id, :text, null: false
      add :target_id, :text, null: false
      add :email_address, :text
      add :token_hash, :binary
      add :token_expires_at, :utc_datetime_usec
      add :expires_at, :utc_datetime_usec, null: false
      add :consumed_at, :utc_datetime_usec
      timestamps(type: :utc_datetime_usec)
    end

    create index(:bonfire_data_identity_pending_action, [:account_id])
    create index(:bonfire_data_identity_pending_action, [:expires_at])
  end
end
