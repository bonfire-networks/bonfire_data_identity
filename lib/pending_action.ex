defmodule Bonfire.Data.Identity.PendingAction do
  @moduledoc "Stored intent and one-time email proof for a sensitive action."
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "bonfire_data_identity_pending_action" do
    field :action, :string
    field :account_id, :string
    field :target_id, :string
    field :email_address, :string, redact: true
    field :token_hash, :binary, redact: true
    field :token_expires_at, :utc_datetime_usec
    field :expires_at, :utc_datetime_usec
    field :consumed_at, :utc_datetime_usec
    timestamps(type: :utc_datetime_usec)
  end

  @doc "Validates server-supplied action context; identity fields are never cast from request parameters."
  def changeset(action, attrs) do
    action
    |> Ecto.Changeset.change(attrs)
    |> Ecto.Changeset.validate_required([:action, :account_id, :target_id, :expires_at])
  end
end
