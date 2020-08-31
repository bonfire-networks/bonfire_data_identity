defmodule CommonsPub.Accounts.Account do
  @moduledoc """
  An account is an identity for authentication purposes. An account
  has one or more credentials with which it may identify.
  """

  use Pointers.Pointable,
    otp_app: :cpub_accounts,
    table_id: "ACC0VNTSARE1S01AT10NGR0VPS",
    source: "cpub_accounts_account"

  alias CommonsPub.Accounts.Account
  alias Pointers.Changesets

  pointable_schema do
  end

  def changeset(account \\ %Account{}, attrs, opts \\ []),
    do: Changesets.auto(account, attrs, opts, [])

end
defmodule CommonsPub.Accounts.Account.Migration do

  use Ecto.Migration
  import Pointers.Migration
  alias CommonsPub.Accounts.Account

  def migrate_account(dir \\ direction())
  def migrate_account(:up) do
    create_pointable_table(Account) do
    end
  end

  def migrate_account(:down) do
    drop_pointable_table(Account)
  end

end
