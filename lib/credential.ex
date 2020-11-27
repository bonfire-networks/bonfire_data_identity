defmodule Bonfire.Data.Identity.Credential do
  @moduledoc """
  A Mixin that provides a local database login identity, i.e. a
  username/email/etc. and passwowrd.
  """

  use Pointers.Mixin,
    otp_app: :bonfire_data_identity,
    source: "bonfire_data_identity_credential"

  require Pointers.Changesets
  alias Bonfire.Data.Identity.Credential
  alias Ecto.Changeset
  alias Pointers.Changesets

  mixin_schema do
    field :identity, :string
    field :password, :string, virtual: true
    field :password_hash, :string
  end

  @defaults [
    cast:     [:identity, :password],
    required: [:identity, :password],
  ]

  def changeset(cred \\ %Credential{}, attrs, opts \\ []) do
    Changesets.auto(cred, attrs, opts, @defaults)
    |> Changeset.unique_constraint(:identity)
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
        add :identity, :text, null: false
        add :password_hash, :text, null: false
        unquote_splicing(exprs)
      end
    end
  end

  defmacro create_credential_table(), do: make_credential_table([])
  defmacro create_credential_table([do: {_, _, body}]), do: make_credential_table(body)

  # drop_credential_table/0

  def drop_credential_table(), do: drop_mixin_table(Credential)

  defp make_credential_identity_index(opts) do
    quote do
      Ecto.Migration.create_if_not_exists(
        Ecto.Migration.unique_index(unquote(@credential_table), [:identity_id], unquote(opts))
      )
    end
  end

  defmacro create_credential_identity_index(opts \\ [])
  defmacro create_credential_identity_index(opts), do: make_credential_identity_index(opts)

  def drop_credential_identity_index(opts \\ []) do
    drop_if_exists(index(@credential_table, [:identity_id], opts))
  end

  # migrate_credential/{0,1}

  defp ma(:up) do
    quote do
      unquote(make_credential_table([]))
      unquote(make_credential_identity_index([]))
    end
  end

  defp ma(:down) do
    quote do
      Bonfire.Data.Identity.Credential.Migration.drop_credential_identity_index()
      Bonfire.Data.Identity.Credential.Migration.drop_credential_table()
    end
  end

  defmacro migrate_credential() do
    quote do
      if Ecto.Migration.direction() == :up,
        do: unquote(ma(:up)),
        else: unquote(ma(:down))
    end
  end
  defmacro migrate_credential(dir), do: ma(dir)

end
