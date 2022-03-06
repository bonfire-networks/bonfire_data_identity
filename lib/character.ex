defmodule Bonfire.Data.Identity.Character do
  @moduledoc """
  A username mixin that denies reuse of the same or similar usernames
  even when the username has been deleted.
  """

  use Pointers.Mixin,
    otp_app: :bonfire_data_identity,
    source: "bonfire_data_identity_character"

  alias Bonfire.Data.Identity.Character
  alias Ecto.Changeset
  alias Pointers.Changesets
  alias Pointers.Pointer
  alias Pointers.ULID

  mixin_schema do
    field :username, :string, redact: true
    field :username_hash, :string

    # Feeds
    belongs_to :outbox, Bonfire.Data.Social.Feed
    belongs_to :inbox, Bonfire.Data.Social.Feed
    belongs_to :notifications, Bonfire.Data.Social.Feed
  end

  @cast     [:id, :username, :outbox_id, :inbox_id, :notifications_id]
  @required [:id, :username]

  def changeset(char \\ %Character{}, params, extra \\ nil)
  def changeset(char, params, nil) do
    char
    |> Changeset.cast(params, @cast)
    |> Changeset.validate_required(@required)
    |> Changeset.unique_constraint(:username)
    |> cast_boxes(params)
    |> Changeset.cast_assoc(:outbox)
    |> Changeset.cast_assoc(:inbox)
    |> Changeset.cast_assoc(:notifications)
    # |> IO.inspect()
  end
  def changeset(char, params, :update) do
    char
    # |> IO.inspect
    |> Changeset.cast(params, @cast)
    # |> Changeset.cast_assoc(:outbox)
    # |> Changeset.cast_assoc(:inbox)
    # |> Changeset.cast_assoc(:notifications)
  end
  def changeset(char, params, :hash) do
    changeset(char, params, nil)
    |> Changeset.unique_constraint(:username_hash)
    |> Changesets.replicate_map_valid_change(:username, :username_hash, &hash/1)
  end

  defp cast_boxes(changeset, params) do
    if changeset.valid? do
      id = Changeset.get_field(changeset, :id)
      boxes =
        for key <- [:outbox, :inbox, :notifications], reduce: %{} do
          acc ->
            Map.put(acc, key, %{
              id: ULID.generate(),
              caretaker: %{caretaker_id: :id},
            })
        end
      Changeset.cast(changeset, boxes, [])
    else
      changeset
    end
  end

  def hash(name) do
    :crypto.hash(:sha256, uniform(name))
    |> Base.encode64(padding: false)
  end

  def uniform(name) do
    name
    |> String.downcase(:ascii)
    |> String.replace(~r/[0123578i_]/, &fold/1)
  end

  defp fold("0"), do: "o"
  defp fold("1"), do: "l"
  defp fold("2"), do: "z"
  defp fold("3"), do: "e"
  defp fold("5"), do: "s"
  defp fold("7"), do: "l"
  defp fold("8"), do: "b"
  defp fold("i"), do: "l"
  defp fold("_"), do: ""

end

defmodule Bonfire.Data.Identity.Character.Migration do

  import Ecto.Migration
  alias Bonfire.Data.Identity.Character

  @character_table Character.__schema__(:source)

  # create_character_table/{0,1}

  defp make_character_table(exprs) do
    quote do
      require Pointers.Migration
      Pointers.Migration.create_mixin_table(Bonfire.Data.Identity.Character) do
        Ecto.Migration.add :username, :citext
        Ecto.Migration.add :username_hash, :citext

        add :outbox_id, Pointers.Migration.weak_pointer()
        add :inbox_id, Pointers.Migration.weak_pointer()
        add :notifications_id, Pointers.Migration.weak_pointer()

        unquote_splicing(exprs)
      end
    end
  end

  defmacro create_character_table(), do: make_character_table([])
  defmacro create_character_table([do: {_, _, body}]), do: make_character_table(body)

  # drop_character_table/0

  def drop_character_table(), do: drop_if_exists(table(@character_table))

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
    drop_character_trigger(opts) # because there is no create trigger if not exists
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
