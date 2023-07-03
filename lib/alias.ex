defmodule Bonfire.Data.Identity.Alias do
  use Pointers.Virtual,
    otp_app: :bonfire_data_social,
    table_id: "7NA11ASA1S0KN0WNASFACESWAP",
    source: "bonfire_data_social_alias"

  alias Bonfire.Data.Edges.Edge
  alias Bonfire.Data.Identity.Alias
  alias Pointers.Changesets

  virtual_schema do
    has_one(:edge, Edge, foreign_key: :id)
  end

  def changeset(alias \\ %Alias{}, params),
    do: Changesets.cast(alias, params, [])
end

defmodule Bonfire.Data.Identity.Alias.Migration do
  @moduledoc false
  import Ecto.Migration
  import Pointers.Migration
  import Bonfire.Data.Edges.Edge.Migration
  alias Bonfire.Data.Identity.Alias

  def migrate_alias_view(), do: migrate_virtual(Alias)

  def migrate_alias_unique_index(), do: migrate_type_unique_index(Alias)

  def migrate_alias(dir \\ direction())

  def migrate_alias(:up) do
    migrate_alias_view()
    migrate_alias_unique_index()
  end

  def migrate_alias(:down) do
    migrate_alias_unique_index()
    migrate_alias_view()
  end
end
