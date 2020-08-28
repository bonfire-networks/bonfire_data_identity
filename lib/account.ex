defmodule CommonsPub.Accounts.Account do
  @moduledoc """
  An account is an identity for authentication purposes. An account
  has one or more credentials with which it may identify.
  """

  use Pointers.Pointable,
    otp_app: :cpub_accounts,
    table_id: "DEVSER1S0STENS1B1YHVMAN01D",
    source: "cpub_accounts_account"

  alias CommonsPub.Accounts.Account
  alias Pointers.Changesets

  @cast []
  @required []
    
  pointable_schema do
  end

  def changeset(account \\ %Account{}, attrs) do
    config = Changesets.config(Changesets.verb(account), [])
    account
    |> Changesets.rename_cast(attrs, config, @cast)
    |> Changesets.validate_required(attrs, config, @required)
  end

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
