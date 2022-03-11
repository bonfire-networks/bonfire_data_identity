defmodule Bonfire.Data.Identity.Account do
  @moduledoc """
  An account is an identity for authentication purposes. An account
  has one or more credentials with which it may identify.
  """

  use Pointers.Virtual,
    otp_app: :bonfire_data_identity,
    table_id: "2CC0VNTSARE1S01AT10NGR0VPS",
    source: "bonfire_data_identity_account"

  alias Bonfire.Data.Identity.{Account, Accounted}
  alias Ecto.Changeset
  alias Pointers.Changesets

  virtual_schema do
    has_many :accounted, Accounted, foreign_key: :account_id
  end

  def changeset(account \\ %Account{}, params), do: Changesets.cast(account, params, [])

end
defmodule Bonfire.Data.Identity.Account.Migration do

  use Ecto.Migration
  import Pointers.Migration
  alias Bonfire.Data.Identity.Account

  # create_account_view/{0,1}

  defp make_account_view() do
    quote do
      require Pointers.Migration
      Pointers.Migration.create_virtual(Bonfire.Data.Identity.Account)
    end
  end

  defmacro create_account_view(), do: make_account_view()

  # drop_account_view/0

  def drop_account_view(), do: drop_virtual(Account)

  # migrate_account/{0,1}

  defp ma(:up), do: make_account_view()

  defp ma(:down) do
    quote do: Bonfire.Data.Identity.Account.Migration.drop_account_view()
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
