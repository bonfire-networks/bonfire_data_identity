defmodule Bonfire.Data.Identity.User do
  @moduledoc """
  A persona. A person (account) may have more than one user, but this
  is not exposed publically (except to local instance administrators),
  so it is as if they are different people.
  """

  use Pointers.Pointable,
    otp_app: :bonfire_data_identity,
    table_id: "DEVSER1S0STENS1B1YHVMAN01D",
    source: "bonfire_data_identity_user"

  alias Bonfire.Data.Identity.User
  alias Ecto.Changeset

  pointable_schema do
  end

  def changeset(user \\ %User{}, params) do
    Changeset.cast(user, params, [])
  end

end
defmodule Bonfire.Data.Identity.User.Migration do

  use Ecto.Migration
  import Pointers.Migration
  alias Bonfire.Data.Identity.User

  # create_user_table/{0,1}

  defp make_user_table(exprs) do
    quote do
      require Pointers.Migration
      Pointers.Migration.create_pointable_table(Bonfire.Data.Identity.User) do
        unquote_splicing(exprs)
      end
    end
  end

  defmacro create_user_table(), do: make_user_table([])
  defmacro create_user_table([do: {_, _, body}]), do: make_user_table(body)

  # drop_user_table/0

  def drop_user_table(), do: drop_pointable_table(User)

  # migrate_user/{0,1}

  defp mu(:up), do: make_user_table([])

  defp mu(:down) do
    quote do: Bonfire.Data.Identity.User.Migration.drop_user_table()
  end

  defmacro migrate_user() do
    quote do
      if Ecto.Migration.direction() == :up,
        do: unquote(mu(:up)),
        else: unquote(mu(:down))
    end
  end
  defmacro migrate_user(dir), do: mu(dir)

end
