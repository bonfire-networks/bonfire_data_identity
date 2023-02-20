defmodule Bonfire.Data.Identity.CareClosure do
  @moduledoc """
  A recursive view of all entities taken care of by their root entities.

  Really, really do not query this without providing a branch_id.
  """

  use Ecto.Schema
  import Ecto.Query, only: [from: 2]
  alias Pointers.Pointer
  alias Bonfire.Data.Identity.CareClosure

  @primary_key false
  schema "bonfire_data_identity_care_closure" do
    belongs_to(:branch_id, Pointer)
    belongs_to(:leaf_id, Pointer)
    field(:path, {:array, Pointers.ULID})
  end

  def by_branch(branch) when not is_list(branch), do: by_branch([branch])

  def by_branch(branches) do
    branches = Enum.map(branches, &id!/1)

    from(p in Pointer,
      join: cc in CareClosure,
      on: p.id == cc.leaf_id and cc.branch_id in ^branches
    )
  end

  defp id!(id) when is_binary(id), do: id
  defp id!(%{id: id}), do: id
end

defmodule Bonfire.Data.Identity.CareClosure.Migration do
  @moduledoc false
  import Ecto.Migration
  alias Pointers.Pointer
  alias Bonfire.Data.Identity.Caretaker

  @pointer_table Pointer.__schema__(:source)
  @caretaker_table Caretaker.__schema__(:source)

  # migrate_care_closure_view/0

  @create_view """
  create or replace view bonfire_data_identity_care_closure as
  with recursive with_closure(branch_id, leaf_id, caretaker_id, path) as (
    -- In the base case, branch_id = leaf_id = caretaker_id. This ensures branch_id occurs in the
    -- list of returned leaf_id for a given branch_id.
    select
      p.id,
      p.id,
      p.id,
      ARRAY[p.id]
    from "#{@pointer_table}" p
  union all
    -- The recursive case just selects from caretaker, joining via the last caretaker_id
    select
      wc.branch_id,
      ct.id,
      ct.caretaker_id,
      wc.path || ct.id
    from "#{@caretaker_table}" ct
    join with_closure wc on ct.id = wc.caretaker_id
    where not ct.id = ANY(wc.path)
  )
  -- The wrapper query is trivial
  select branch_id, leaf_id, path
  from with_closure
  """

  @drop_view """
  drop view if exists bonfire_data_identity_care_closure
  """

  def migrate_care_closure_view(), do: execute(@create_view, @drop_view)
end
