defmodule Bonfire.Data.Identity.Language do
  use Needle.Mixin,
    otp_app: :bonfire_data_identity,
    source: "bonfire_data_identity_language"

  alias Bonfire.Data.Identity.Language
  alias Ecto.Changeset

  mixin_schema do
    field(:locale, :string)
  end

  @cast [:locale]
  @required [:locale]

  def changeset(language \\ %Language{}, attrs) do
    language
    |> Changeset.cast(attrs, @cast)
    |> Changeset.validate_required(@required)

    # |> Changeset.validate_inclusion(:locale, Bonfire.Common.Localise.known_locale_names()) # TODO: because known_locale_names contains atoms
  end
end

defmodule Bonfire.Data.Identity.Language.Migration do
  @moduledoc false
  use Ecto.Migration
  import Needle.Migration
  alias Bonfire.Data.Identity.Language

  defp make_language_table(exprs) do
    quote do
      require Needle.Migration

      Needle.Migration.create_mixin_table Bonfire.Data.Identity.Language do
        Ecto.Migration.add(:locale, :string, null: false)

        unquote_splicing(exprs)
      end
    end
  end

  defmacro create_language_table(), do: make_language_table([])
  defmacro create_language_table(do: {_, _, body}), do: make_language_table(body)

  def drop_language_table(), do: drop_mixin_table(Language)

  defp mcd(:up), do: make_language_table([])

  defp mcd(:down) do
    quote do
      Bonfire.Data.Identity.Language.Migration.drop_language_table()
    end
  end

  defmacro migrate_language() do
    quote do
      if Ecto.Migration.direction() == :up,
        do: unquote(mcd(:up)),
        else: unquote(mcd(:down))
    end
  end

  defmacro migrate_language(dir), do: mcd(dir)
end
