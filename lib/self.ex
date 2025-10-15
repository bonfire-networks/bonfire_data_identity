defmodule Bonfire.Data.Identity.Self do
  use Needle.Mixin,
    otp_app: :bonfire_data_identity,
    source: "bonfire_data_identity_self"

  alias Bonfire.Data.AccessControl.Acl
  alias Bonfire.Data.Identity.Self
  alias Ecto.Changeset

  mixin_schema do
    belongs_to(:self_acl, Acl)
    belongs_to(:admin_acl, Acl)
  end

  @cast [:self_acl, :admin_acl]
  @required [:self_acl, :admin_acl]

  def changeset(self \\ %Self{}, params) do
    self
    |> Changeset.cast(params, @cast)
    |> Changeset.validate_required(@required)
    |> Changeset.assoc_constraint(:self_acl)
    |> Changeset.assoc_constraint(:admin_acl)
  end
end

defmodule Bonfire.Data.Identity.Self.Migration do
  @moduledoc false
  use Ecto.Migration
  import Needle.Migration
  alias Bonfire.Data.Identity.Self

  # create_self_table/{0,1}

  defp make_self_table(exprs) do
    quote do
      import Needle.Migration

      Needle.Migration.create_mixin_table Bonfire.Data.Identity.Self do
        add_pointer(:self_acl_id, :strong, Bonfire.Data.AccessControl.Acl, null: false)
        add_pointer(:admin_acl_id, :strong, Bonfire.Data.AccessControl.Acl, null: false)

        unquote_splicing(exprs)
      end
    end
  end

  defmacro create_self_table(), do: make_self_table([])
  defmacro create_self_table(do: {_, _, body}), do: make_self_table(body)

  # drop_self_table/0

  def drop_self_table(), do: drop_mixin_table(Self)

  # migrate_self/{0,1}

  defp ms(:up), do: make_self_table([])

  defp ms(:down) do
    quote do: Bonfire.Data.Identity.Self.Migration.drop_self_table()
  end

  defmacro migrate_self() do
    quote do
      if Ecto.Migration.direction() == :up,
        do: unquote(ms(:up)),
        else: unquote(ms(:down))
    end
  end

  defmacro migrate_self(dir), do: ms(dir)
end
