defmodule Bonfire.Data.Identity.Credential do
  @moduledoc """
  A Mixin that provides a password for local login.
  """

  use Pointers.Mixin,
    otp_app: :bonfire_data_identity,
    source: "bonfire_data_identity_credential"

  import Where
  require Pointers.Changesets
  alias Bonfire.Data.Identity.Credential
  alias Ecto.Changeset
  alias Pointers.Changesets

  mixin_schema do
    field :password, :string, virtual: true, redact: true
    field :password_hash, :string
  end

  @cast     [:password]
  @required [:password]

  def changeset(cred \\ %Credential{}, params) do
    cred
    |> Changeset.cast(params, @cast)
    |> Changeset.validate_required(@required)
    |> Changeset.validate_length(:password, min: 10, max: 64)
    |> Changesets.replicate_map_valid_change(:password, :password_hash, &hash_password/1)
  end

  def confirmation_changeset(cred \\ %Credential{}, params) do
    cred
    |> changeset(params)
    |> Changeset.validate_confirmation(:password)
  end

  @module Application.compile_env(:bonfire_data_identity, [__MODULE__, :hasher_module], Argon2)

  def hash_password(password), do: @module.hash_pwd_salt(password)
  def check_password(password, hash), do: @module.verify_pass(password, hash)
  def dummy_check(), do: @module.no_user_verify()

end
defmodule Bonfire.Data.Identity.Credential.Migration do

  # import Ecto.Migration
  import Pointers.Migration
  alias Bonfire.Data.Identity.Credential

  # @credential_table Credential.__schema__(:source)

  # create_credential_table/{0,1}

  defp make_credential_table(exprs) do
    quote do
      require Pointers.Migration
      Pointers.Migration.create_mixin_table(Bonfire.Data.Identity.Credential) do
        Ecto.Migration.add :password_hash, :text, null: false
        unquote_splicing(exprs)
      end
    end
  end

  defmacro create_credential_table(), do: make_credential_table([])
  defmacro create_credential_table([do: {_, _, body}]), do: make_credential_table(body)

  # drop_credential_table/0

  def drop_credential_table(), do: drop_mixin_table(Credential)

  # migrate_credential/{0,1}

  defp mc(:up), do: make_credential_table([])

  defp mc(:down) do
    quote do
      Bonfire.Data.Identity.Credential.Migration.drop_credential_table()
    end
  end

  defmacro migrate_credential() do
    quote do
      if Ecto.Migration.direction() == :up,
        do: unquote(mc(:up)),
        else: unquote(mc(:down))
    end
  end
  defmacro migrate_credential(dir), do: mc(dir)

end
