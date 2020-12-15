defmodule Bonfire.Data.Identity.Credential do
  @moduledoc """
  A Mixin that provides a password for local login.
  """

  use Pointers.Mixin,
    otp_app: :bonfire_data_identity,
    source: "bonfire_data_identity_credential"

  require Pointers.Changesets
  alias Bonfire.Data.Identity.Credential
  alias Ecto.Changeset
  alias Pointers.Changesets

  mixin_schema do
    field :password, :string, virtual: true, redact: true
    field :password_hash, :string
  end

  @defaults [
    cast:     [:password],
    required: [:password],
  ]

  def changeset(cred \\ %Credential{}, attrs, opts \\ []) do
    Changesets.auto(cred, attrs, opts, @defaults)
    |> hash_password()
  end

  def hash_password(%Changeset{valid?: true, changes: %{password: password}}=changeset),
    do: Changeset.change(changeset, Argon2.add_hash(password))
  def hash_password(changeset), do: changeset

end
defmodule Bonfire.Data.Identity.Credential.Migration do

  import Ecto.Migration
  import Pointers.Migration
  alias Bonfire.Data.Identity.Credential

  @credential_table Credential.__schema__(:source)

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
