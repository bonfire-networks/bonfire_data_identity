defmodule Bonfire.Data.Identity.Character do

  use Pointers.Mixin,
    otp_app: :bonfire_data_identity,
    source: "bonfire_data_identity_character"

  alias Pointers.Changesets
  require Pointers.Changesets
  alias Bonfire.Data.Identity.Character
  alias Ecto.Changeset
  
  mixin_schema do
    field :username, :string
    field :username_hash, :string
  end

  @defaults [
    cast:     [:username],
    required: [:username],
    username: [ format: ~r(^[a-z][a-z0-9_]{2,30}$)i ],
  ]

  def changeset(char \\ %Character{}, attrs, opts \\ []) do
    Changesets.auto(char, attrs, opts, @defaults)
    |> Changesets.replicate_map_valid_change(:username, :username_hash, &hash/1)
    |> Changeset.unique_constraint(:username)
    |> Changeset.unique_constraint(:username_hash)
  end

  def hash(name) do
    :crypto.hash(:blake2b, uniform(name))
    |> Base.encode64(padding: false)
  end

  def uniform(name) do
    name
    |> String.downcase(:ascii)
    |> String.replace(~r/[0125_]/, &fold/1)
  end

  defp fold("0"), do: "o"
  defp fold("1"), do: "i"
  defp fold("2"), do: "z"
  defp fold("5"), do: "s"
  defp fold("_"), do: ""

  def redact(%Character{}=char), do: Changeset.change(char, username: nil)

end
defmodule Bonfire.Data.Identity.Character.Migration do

  import Ecto.Migration
  import Pointers.Migration
  alias Bonfire.Data.Identity.Character

  @character_table Character.__schema__(:source)

  # create_character_table/{0,1}

  defp make_character_table(exprs) do
    quote do
      require Pointers.Migration
      Pointers.Migration.create_mixin_table(Bonfire.Data.Identity.Character) do
        Ecto.Migration.add :username, :citext
        Ecto.Migration.add :username_hash, :citext, null: false
        unquote_splicing(exprs)
      end
    end
  end

  defmacro create_character_table(), do: make_character_table([])
  defmacro create_character_table([do: {_, _, body}]), do: make_character_table(body)

  # drop_character_table/0

  def drop_character_table(), do: drop_mixin_table(Character)

  # create_character_username_index/{0, 1}

  defp make_character_username_index(opts) do
    quote do
      Ecto.Migration.create_if_not_exists(
        Ecto.Migration.unique_index(unquote(@character_table), [:username], unquote(opts))
      )
    end
  end

  defmacro create_character_username_index(opts \\ [])
  defmacro create_character_username_index(opts), do: make_character_username_index(opts)

  def drop_character_username_index(opts \\ []) do
    drop_if_exists(unique_index(@character_table, [:username], opts))
  end

  # create_character_username_hash_index/{0, 1}

  defp make_character_username_hash_index(opts) do
    quote do
      Ecto.Migration.create_if_not_exists(
        Ecto.Migration.unique_index(unquote(@character_table), [:username_hash], unquote(opts))
      )
    end
  end

  defmacro create_character_username_hash_index(opts \\ [])
  defmacro create_character_username_hash_index(opts), do: make_character_username_hash_index(opts)

  def drop_character_username_hash_index(opts \\ []) do
    drop_if_exists(unique_index(@character_table, [:username_hash], opts))
  end


  # migrate_character/{0,1}

  defp mc(:up) do
    quote do
      unquote(make_character_table([]))
      unquote(make_character_username_index([]))
      unquote(make_character_username_hash_index([]))
    end      
  end
  defp mc(:down) do
    quote do
      Bonfire.Data.Identity.Character.Migration.drop_character_username_hash_index()
      Bonfire.Data.Identity.Character.Migration.drop_character_username_index()
      Bonfire.Data.Identity.Character.Migration.drop_character_table()
    end
  end

  defmacro migrate_character() do
    quote do
      if Ecto.Migration.direction() == :up,
        do: unquote(mc(:up)),
        else: unquote(mc(:down))
    end
  end
  defmacro migrate_character(dir), do: mc(dir)

end
