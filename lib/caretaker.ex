defmodule Bonfire.Data.Identity.Caretaker do
  @moduledoc """
  The entity responsible for something. In practice, it means that
  something is deleted when its caretaker is deleted.

  You can think of it as being like the creator, except:
  a) You can give it away.
  b) Objects can take care of arbitrary objects, such as e.g. custom
     ACLs created to permit people mentioned special permissions
  """

  use Pointers.Mixin,
    otp_app: :bonfire_data_identity,
    source: "bonfire_data_identity_caretaker"

  alias Bonfire.Data.Identity.Caretaker
  alias Pointers.Pointer
  alias Ecto.Changeset

  mixin_schema do
    belongs_to :caretaker, Pointer
  end

  @cast     [:caretaker_id]
  @required [:caretaker_id]

  def changeset(ct \\ %Caretaker{}, params, _opts \\ []) do
    ct
    |> Changeset.cast(params, @cast)
    |> Changeset.validate_required(@required)
    |> Changeset.foreign_key_constraint(:caretaker_id)
  end

end
defmodule Bonfire.Data.Identity.Caretaker.Migration do

  import Ecto.Migration
  import Pointers.Migration
  alias Bonfire.Data.Identity.Caretaker

  @caretaker_table Caretaker.__schema__(:source)

  # create_caretaker_table/{0,1}

  defp make_caretaker_table(exprs) do
    quote do
      require Pointers.Migration
      Pointers.Migration.create_mixin_table(Bonfire.Data.Identity.Caretaker) do
        add :caretaker_id,
          Pointers.Migration.strong_pointer(), null: false
        unquote_splicing(exprs)
      end
    end
  end

  defmacro create_caretaker_table(), do: make_caretaker_table([])
  defmacro create_caretaker_table([do: {_, _, body}]), do: make_caretaker_table(body)

  # drop_caretaker_table/0

  def drop_caretaker_table(), do: drop_mixin_table(Caretaker)

  # create_caretaker_caretaker_index/{0, 1}

  defp make_caretaker_caretaker_index(opts) do
    quote do
      Ecto.Migration.create_if_not_exists(
        Ecto.Migration.index(unquote(@caretaker_table), [:caretaker_id], unquote(opts))
      )
    end
  end

  defmacro create_caretaker_caretaker_index(opts \\ [])
  defmacro create_caretaker_caretaker_index(opts), do: make_caretaker_caretaker_index(opts)

  def drop_caretaker_caretaker_index(opts \\ []) do
    drop_if_exists(index(@caretaker_table, [:caretaker_id], opts))
  end

  # migrate_caretaker/{0,1}

  defp mc(:up) do
    quote do
      unquote(make_caretaker_table([]))
      unquote(make_caretaker_caretaker_index([]))
    end
  end

  defp mc(:down) do
    quote do
      Bonfire.Data.Identity.Caretaker.Migration.drop_caretaker_caretaker_index()
      Bonfire.Data.Identity.Caretaker.Migration.drop_caretaker_table()
    end
  end

  defmacro migrate_caretaker() do
    quote do
      if Ecto.Migration.direction() == :up,
        do: unquote(mc(:up)),
        else: unquote(mc(:down))
    end
  end
  defmacro migrate_caretaker(dir), do: mc(dir)

end
