defmodule Bonfire.Data.Identity.Settings do
  @moduledoc """
  A mixin that stores settings (of the instance, account, user, etc) as an Erlang Term (typically a map or keyword list) encoded to binary.
  """
  use Pointers.Mixin,
    otp_app: :bonfire_data_identity,
    source: "bonfire_data_identity_settings"

  alias Bonfire.Data.Identity.Settings
  alias Ecto.Changeset

  mixin_schema do
    field(:data, EctoSparkles.ErlangTermBinary)
  end

  @cast [:id, :data]

  def changeset(settings \\ %Settings{}, params, opts \\ [])

  def changeset(%Settings{id: _} = settings, params, _opts) do
    # [:data])
    Changeset.cast(settings, params, @cast)
  end

  def changeset(settings, params, _opts) do
    Changeset.cast(settings, params, @cast)
  end
end

defmodule Bonfire.Data.Identity.Settings.Migration do
  use Ecto.Migration
  import Pointers.Migration
  alias Bonfire.Data.Identity.Settings

  # create_settings_table/{0,1}

  defp make_settings_table(exprs) do
    quote do
      require Pointers.Migration

      Pointers.Migration.create_mixin_table Bonfire.Data.Identity.Settings do
        Ecto.Migration.add(:data, :binary, null: true)
        unquote_splicing(exprs)
      end
    end
  end

  defmacro create_settings_table(), do: make_settings_table([])

  defmacro create_settings_table(do: {_, _, body}),
    do: make_settings_table(body)

  # drop_settings_table/0

  def drop_settings_table(), do: drop_mixin_table(Settings)

  # migrate_settings/{0,1}

  defp mn(:up), do: make_settings_table([])

  defp mn(:down) do
    quote do
      Bonfire.Data.Identity.Settings.Migration.drop_settings_table()
    end
  end

  defmacro migrate_settings() do
    quote do
      if Ecto.Migration.direction() == :up,
        do: unquote(mn(:up)),
        else: unquote(mn(:down))
    end
  end

  defmacro migrate_settings(dir), do: mn(dir)
end
