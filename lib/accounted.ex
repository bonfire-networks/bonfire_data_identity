defmodule CommonsPub.Accounts.Accounted do
  @moduledoc """
  A mixin for an account ID, indicating ownership

  Primarily used for Users.
  """

  use Pointers.Mixin,
    otp_app: :cpub_accounts,
    source: "cpub_accounts_accounted"

  alias CommonsPub.Accounts.{Account, Accounted}
  alias Pointers.Changesets
  alias Ecto.Changeset

  mixin_schema do
    belongs_to :account, Account
  end

  @defaults [
    cast: [:id, :account_id],
    required: [:account_id],
  ]

  def changeset(t \\ %Accounted{}, attrs, opts \\ []) do
    Changesets.auto(t, attrs, opts, @defaults)
    |> Changeset.foreign_key_constraint(:account_id)
  end

end
defmodule CommonsPub.Accounts.Accounted.Migration do

  import Ecto.Migration
  import Pointers.Migration
  alias CommonsPub.Accounts.{Account, Accounted}

  def migrate_accounted(index_opts \\ []),
    do: migrate_accounted(index_opts, direction())

  defp accounted_table(), do: Accounted.__schema__(:source)

  defp migrate_accounted(index_opts, :up) do
    create_mixin_table(Accounted) do
      add :account_id, strong_pointer(Account), null: false 
    end
    create_if_not_exists(unique_index(accounted_table(), [:account_id], index_opts))
  end

  defp migrate_accounted(_index_opts, :down) do
    drop_if_exists(index(accounted_table(), [:account_id]))
    drop_mixin_table(accounted_table())
  end

end
