defmodule Bonfire.Data.Identity.ExtraInfo do
  use Needle.Mixin,
    otp_app: :bonfire_data_identity,
    source: "bonfire_data_social_extra_info"

  alias Bonfire.Data.Identity.ExtraInfo
  alias Ecto.Changeset

  mixin_schema do
    field(:summary, :string)
    field(:info, :map)
  end

  @cast [:summary, :info]

  def changeset(extra_info \\ %ExtraInfo{}, params, _opts \\ []) do
    Changeset.cast(extra_info, params, @cast)
  end
end

defmodule Bonfire.Data.Identity.ExtraInfo.Migration do
  @moduledoc false
  use Ecto.Migration
  import Needle.Migration
  alias Bonfire.Data.Identity.ExtraInfo

  # create_extra_info_table/{0,1}

  defp make_extra_info_table(exprs) do
    quote do
      require Needle.Migration

      Needle.Migration.create_mixin_table Bonfire.Data.Identity.ExtraInfo do
        Ecto.Migration.add(:summary, :text)
        Ecto.Migration.add(:info, :jsonb)
        unquote_splicing(exprs)
      end
    end
  end

  defmacro create_extra_info_table(), do: make_extra_info_table([])

  defmacro create_extra_info_table(do: {_, _, body}),
    do: make_extra_info_table(body)

  # drop_extra_info_table/0

  def drop_extra_info_table(), do: drop_mixin_table(ExtraInfo)

  # migrate_extra_info/{0,1}

  defp mn(:up), do: make_extra_info_table([])

  defp mn(:down) do
    quote do
      Bonfire.Data.Identity.ExtraInfo.Migration.drop_extra_info_table()
    end
  end

  defmacro migrate_extra_info() do
    quote do
      if Ecto.Migration.direction() == :up,
        do: unquote(mn(:up)),
        else: unquote(mn(:down))
    end
  end

  defmacro migrate_extra_info(dir), do: mn(dir)
end
