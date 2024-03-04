defmodule Bonfire.Data.Identity.AuthSecondFactor do
  @moduledoc """
  A mixin that stores a second factor secret to authenticate an account.
  """
  use Needle.Mixin,
    otp_app: :bonfire_data_identity,
    source: "bonfire_data_identity_auth_second_factor"

  import Untangle
  alias Bonfire.Data.Identity.AuthSecondFactor
  # alias Ecto.Changeset

  mixin_schema do
    field(:secret, :binary, redact: true)
    field(:code, :string, virtual: true)

    # TODO: implement backup codes
    # embeds_many :backup_codes, BackupCode, on_replace: :delete do
    #   field :code, :string
    #   field :used_at, :utc_datetime_usec
    # end
  end

  @cast [:id, :secret, :code]
  @required [:secret, :code]

  def changeset(%AuthSecondFactor{} = totp, attrs) do
    debug(attrs)

    changeset =
      totp
      |> Ecto.Changeset.cast(attrs, @cast)
      |> Ecto.Changeset.validate_required(@required)
      |> Ecto.Changeset.validate_format(:code, ~r/^\d{6}$/, message: "should be a 6 digit number")

    code = Needle.Changesets.get_field(changeset, :code)

    if changeset.valid? and not valid_totp?(totp, code) do
      if not is_binary(totp.secret),
        do:
          Ecto.Changeset.add_error(
            changeset,
            :code,
            "invalid secret, please scan the QR code again"
          ),
        else: Ecto.Changeset.add_error(changeset, :code, "invalid code")
    else
      changeset
    end
  end

  def valid_totp?(%AuthSecondFactor{} = totp, code) do
    debug(totp.secret)
    debug(code)

    is_binary(totp.secret) and is_binary(code) and byte_size(code) == 6 and
      NimbleTOTP.valid?(totp.secret, code)
  end

  # def validate_backup_code(totp, code) when is_binary(code) do
  #   totp.backup_codes
  #   |> Enum.map_reduce(false, fn backup, valid? ->
  #     if Plug.Crypto.secure_compare(backup.code, code) and is_nil(backup.used_at) do
  #       {Ecto.Changeset.change(backup, %{used_at: DateTime.utc_now()}), true}
  #     else
  #       {backup, valid?}
  #     end
  #   end)
  #   |> case do
  #     {backup_codes, true} ->
  #       totp
  #       |> Ecto.Changeset.change()
  #       |> Ecto.Changeset.put_embed(:backup_codes, backup_codes)

  #     {_, false} ->
  #       nil
  #   end
  # end

  # def validate_backup_code(_totp, _code), do: nil

  # def regenerate_backup_codes(changeset) do
  #   Ecto.Changeset.put_embed(changeset, :backup_codes, generate_backup_codes())
  # end

  # def ensure_backup_codes(changeset) do
  #   case Needle.Changesets.get_field(changeset, :backup_codes) do
  #     [] -> regenerate_backup_codes(changeset)
  #     _ -> changeset
  #   end
  # end

  # defp generate_backup_codes do
  #   for letter <- Enum.take_random(?A..?Z, 10) do
  #     suffix =
  #       :crypto.strong_rand_bytes(5)
  #       |> Base.encode32()
  #       |> binary_part(0, 7)

  #     # The first digit is always a letter so we can distinguish
  #     # in the UI between 6 digit TOTP codes and backup ones.
  #     # We also replace the letter O by X to avoid confusion with zero.
  #     code = String.replace(<<letter, suffix::binary>>, "O", "X")
  #     %BackupCode{code: code}
  #   end
  # end
end

defmodule Bonfire.Data.Identity.AuthSecondFactor.Migration do
  @moduledoc false
  use Ecto.Migration
  import Needle.Migration
  alias Bonfire.Data.Identity.AuthSecondFactor

  # create_auth_second_factor_table/{0,1}

  defp make_auth_second_factor_table(exprs) do
    quote do
      require Needle.Migration

      Needle.Migration.create_mixin_table Bonfire.Data.Identity.AuthSecondFactor do
        Ecto.Migration.add(:secret, :binary, null: false)
        unquote_splicing(exprs)
      end
    end
  end

  defmacro create_auth_second_factor_table(),
    do: make_auth_second_factor_table([])

  defmacro create_auth_second_factor_table(do: {_, _, body}),
    do: make_auth_second_factor_table(body)

  # drop_auth_second_factor_table/0

  def drop_auth_second_factor_table(), do: drop_mixin_table(AuthSecondFactor)

  # migrate_auth_second_factor/{0,1}

  defp mn(:up), do: make_auth_second_factor_table([])

  defp mn(:down) do
    quote do
      Bonfire.Data.Identity.AuthSecondFactor.Migration.drop_auth_second_factor_table()
    end
  end

  defmacro migrate_auth_second_factor() do
    quote do
      if Ecto.Migration.direction() == :up,
        do: unquote(mn(:up)),
        else: unquote(mn(:down))
    end
  end

  defmacro migrate_auth_second_factor(dir), do: mn(dir)
end
