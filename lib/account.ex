defmodule Bonfire.Data.Identity.Account do
  @moduledoc """
  An account is an identity for authentication purposes. An account
  has one or more credentials with which it may identify.
  """

  use Pointers.Pointable,
    otp_app: :bonfire_data_identity,
    table_id: "ACC0VNTSARE1S01AT10NGR0VPS",
    source: "bonfire_data_identity_account"

  alias Bonfire.Data.Identity.Account
  alias Pointers.Changesets

  pointable_schema do
  end

  def changeset(account \\ %Account{}, attrs, opts \\ []),
    do: Changesets.auto(account, attrs, opts, [])

end
defmodule Bonfire.Data.Identity.Account.Migration do

  use Ecto.Migration
  import Pointers.Migration
  alias Bonfire.Data.Identity.Account

  # create_account_table/{0,1}

  defp make_account_table(exprs) do
    quote do
      require Pointers.Migration
      Pointers.Migration.create_pointable_table(Bonfire.Data.Identity.Account) do
        unquote_splicing(exprs)
      end
    end
  end

  defmacro create_account_table(), do: make_account_table([])
  defmacro create_account_table([do: {_, _, body}]), do: make_account_table(body)

  # drop_account_table/0

p  def drop_account_table(), do: drop_pointable_table(Account)

  # migrate_account/{0,1}

  defp ma(:up), do: make_account_table([])

  defp ma(:down) do
    quote do: Bonfire.Data.Identity.Account.Migration.drop_account_table()
  end

  defmacro migrate_account() do
    quote do
      if Ecto.Migration.direction() == :up,
        do: unquote(ma(:up)),
        else: unquote(ma(:down))
    end
  end
  defmacro migrate_account(dir), do: ma(dir)

end
