defmodule Bonfire.Data.Identity.Character do
  @moduledoc """
  A username mixin that denies reuse of the same or *visually similar* usernames, even after a username has been deleted.

  ## Why

  Each character stores a `username_hash` alongside its `username`. The hash is covered by a unique index, so it acts as a second uniqueness guarantee that:

    * survives username deletion (the row is kept, only `username` is nulled by a DB trigger), preventing a freed handle from being silently re-registered, and
    * catches *confusable* usernames — handles that look alike to a human but differ byte-for-byte (e.g. `bob1` vs `bobl`) — so they cannot be used to impersonate or squat on each other.

  ## How

  `hash/1` builds the hash by running the username through `uniform/1` (which canonicalises confusable characters), then SHA-256 + unpadded Base64. Two usernames that `uniform/1` maps to the same string therefore share a hash and are treated as the same identity.
  """

  use Needle.Mixin,
    otp_app: :bonfire_data_identity,
    source: "bonfire_data_identity_character"

  alias Bonfire.Data.Identity.Caretaker
  alias Bonfire.Data.Identity.Character

  alias Bonfire.Data.Social.Feed
  alias Ecto.Changeset
  alias Needle.Changesets
  import Untangle

  mixin_schema do
    field(:username, :string,
      redact: Bonfire.Data.Identity.User.maybe_redact(Application.compile_env(:bonfire, :env))
    )

    field(:username_hash, :string, redact: true)
    belongs_to(:outbox, Feed)
    belongs_to(:inbox, Feed)
    belongs_to(:notifications, Feed)
  end

  @cast [:username]
  @required [:username]

  def changeset_basic(char, params) do
    # debug(params)

    char
    |> debug()
    |> Changeset.cast(params, @cast)

    # |> Changesets.cast_assoc(:actor)
  end

  def changeset(char \\ %Character{}, params, extra \\ nil)

  def changeset(char, params, nil) do
    changeset_basic(char, params)
    |> Changeset.validate_required(@required)
    |> Changeset.unique_constraint(:username)
    |> put_boxes(params)

    # |> IO.inspect()
  end

  def changeset(char, params, :update) do
    changeset_basic(char, params)
  end

  def changeset(char, params, :hash) do
    changeset(char, params, nil)
    |> Changeset.unique_constraint(:username_hash)
    |> Changesets.replicate_map_valid_change(:username, :username_hash, &hash/1)
  end

  defp put_boxes(changeset, _params) do
    if changeset.valid? and changeset.data.__meta__.state == :built do
      # || raise "Character requires an ID to be set on the pointable." # FIXME
      id = Needle.Changesets.get_field(changeset, :id)
      # debug(id, "changeset id")
      for key <- [:outbox, :inbox, :notifications], reduce: changeset do
        changeset ->
          Changesets.put_assoc!(changeset, key, %{})
          |> Changeset.update_change(key, &maybe_caretaker(&1, id))
      end
    else
      changeset
    end
  end

  defp maybe_caretaker(cs, id) when is_binary(id) do
    Changesets.put_assoc!(cs, :caretaker, %Caretaker{caretaker_id: id})
  end

  defp maybe_caretaker(cs, _) do
    warn("The Character assocs are not being given a caretaker")
    cs
  end

  @doc """
  Returns the unique hash used to deny reuse of the same or confusable usernames.

  The name is canonicalised with `uniform/1` (so confusable handles collapse to the same value), then hashed with SHA-256 and Base64-encoded (unpadded).

  ## Examples

      iex> Bonfire.Data.Identity.Character.hash("bob") == Bonfire.Data.Identity.Character.hash("BOB")
      true
  """
  def hash(name) do
    :crypto.hash(:sha256, uniform(name))
    |> Base.encode64(padding: false)
  end

  @doc """
  Canonicalises a username for hashing by lowercasing it and folding visually confusable characters (see `fold/1`).

  ## Examples

      iex> Bonfire.Data.Identity.Character.uniform("B0b_1")
      "bobl"

      iex> Bonfire.Data.Identity.Character.uniform("bob7")
      "bob7"
  """
  def uniform(name) do
    name
    |> String.downcase(:ascii)
    |> String.replace(~r/[012358i_]/, &fold/1)
  end

  @doc false
  # Folds a single confusable character to its canonical form. Note that `7` is
  # deliberately not folded: it is not a strong look-alike for any letter, and
  # folding it to `l` made `…7` usernames collide with `…l`/`…1`/`…i` ones.
  defp fold("0"), do: "o"
  defp fold("1"), do: "l"
  defp fold("2"), do: "z"
  defp fold("3"), do: "e"
  defp fold("5"), do: "s"
  defp fold("8"), do: "b"
  defp fold("i"), do: "l"
  defp fold("_"), do: ""
end

defmodule Bonfire.Data.Identity.Character.Migration do
  @moduledoc false
  import Ecto.Migration
  use Needle.Migration.Indexable
  alias Bonfire.Data.Identity.Character

  @character_table Character.__schema__(:source)

  # create_character_table/{0,1}

  defp make_character_table(exprs) do
    quote do
      import Needle.Migration

      Needle.Migration.create_mixin_table Bonfire.Data.Identity.Character do
        Ecto.Migration.add(:username, :citext)
        Ecto.Migration.add(:username_hash, :citext)

        add_pointer(:outbox_id, :weak)
        add_pointer(:inbox_id, :weak)
        add_pointer(:notifications_id, :weak)

        unquote_splicing(exprs)
      end
    end
  end

  defmacro create_character_table(), do: make_character_table([])

  defmacro create_character_table(do: {_, _, body}),
    do: make_character_table(body)

  # drop_character_table/0

  def drop_character_table(), do: drop_if_exists(table(@character_table))

  # create_character_username_index/{0, 1}

  defp make_character_username_index(opts) do
    quote do
      Ecto.Migration.create_if_not_exists(
        Ecto.Migration.unique_index(
          unquote(@character_table),
          [:username],
          unquote(opts)
        )
      )
    end
  end

  defmacro create_character_username_index(opts \\ [])

  defmacro create_character_username_index(opts),
    do: make_character_username_index(opts)

  def drop_character_username_index(opts \\ []) do
    drop_if_exists(unique_index(@character_table, [:username], opts))
  end

  # create_character_username_hash_index/{0, 1}

  defp make_character_username_hash_index(opts) do
    quote do
      Ecto.Migration.create_if_not_exists(
        Ecto.Migration.unique_index(
          unquote(@character_table),
          [:username_hash],
          unquote(opts)
        )
      )
    end
  end

  defmacro create_character_username_hash_index(opts \\ [])

  defmacro create_character_username_hash_index(opts),
    do: make_character_username_hash_index(opts)

  def drop_character_username_hash_index(opts \\ []) do
    drop_if_exists(unique_index(@character_table, [:username_hash], opts))
  end

  def add_character_feed_indexes do
    create_index_for_pointer(@character_table, :outbox_id)
    create_index_for_pointer(@character_table, :inbox_id)
    create_index_for_pointer(@character_table, :notifications_id)
  end

  @function_up """
  create or replace function bonfire_identity_delete_username()
  returns trigger as $$
  begin
    if NEW.id is null then
      NEW.username = null;
    end if;
    return NEW;
  end;
  $$ language plpgsql
  """
  @function_down """
  drop function if exists delete_username()
  """
  @trigger_up """
  create trigger "#{@character_table}_delete_username_trigger"
  before update on "#{@character_table}"
  for each row execute procedure bonfire_identity_delete_username()
  """

  @trigger_down """
  drop trigger if exists
  "#{@character_table}_delete_username_trigger"
  on "#{@character_table}"
  """

  def create_character_trigger_function(_opts \\ []) do
    execute(@function_up)
  end

  def drop_character_trigger_function(_opts \\ []) do
    execute(@function_down)
  end

  def create_character_trigger(opts \\ []) do
    # because there is no create trigger if not exists
    drop_character_trigger(opts)
    execute(@trigger_up)
  end

  def drop_character_trigger(_opts \\ []) do
    execute(@trigger_down)
  end

  # migrate_character/{0,1}

  defp mc(:up) do
    quote do
      unquote(make_character_table([]))
      unquote(make_character_username_index([]))
      unquote(make_character_username_hash_index([]))
      Ecto.Migration.flush()

      Bonfire.Data.Identity.Character.Migration.add_character_feed_indexes()

      Bonfire.Data.Identity.Character.Migration.create_character_trigger_function()

      Bonfire.Data.Identity.Character.Migration.create_character_trigger()
    end
  end

  defp mc(:down) do
    quote do
      Bonfire.Data.Identity.Character.Migration.drop_character_trigger()

      Bonfire.Data.Identity.Character.Migration.drop_character_trigger_function()

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
