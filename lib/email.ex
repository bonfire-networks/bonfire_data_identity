defmodule Bonfire.Data.Identity.Email do
  use Pointers.Mixin,
    otp_app: :bonfire_data_identity,
    source: "bonfire_data_identity_email"

  alias Bonfire.Data.Identity.Email
  alias Ecto.Changeset
  alias Pointers.Changesets

  @type t() :: %Email{}

  mixin_schema do
    field(:email_address, :string,
      redact: Bonfire.Data.Identity.User.maybe_redact(Application.get_env(:bonfire, :env))
    )

    field(:confirm_token, :string)
    field(:confirm_until, :utc_datetime_usec)
    field(:confirmed_at, :utc_datetime_usec)
  end

  # one day
  @default_confirm_duration {60 * 60 * 24, :second}
  # pretty loose
  @default_email_regex ~r(^[^@]{1,128}@[^@]{2,128}$)

  @doc """
  Options:
    email_regex: Regexp.t (default very minimal validation)
    must_confirm?: bool (default true)
  """
  def changeset(email \\ %Email{}, params, opts \\ []) do
    regex = config(opts, :email_regex, @default_email_regex)

    Changeset.cast(email, params, [:email_address])
    |> Changeset.validate_format(:email_address, regex)
    |> Changeset.validate_required([:email_address])
    |> Changeset.unique_constraint(:email_address)
    |> on_email_change(opts)
  end

  @doc false
  def on_email_change(changeset, opts \\ [])

  def on_email_change(%Changeset{} = cs, opts) do
    if cs.valid? && cs.changes[:email_address] do
      if must_confirm?(opts),
        do: put_token(cs),
        else: confirm(cs)
    else
      cs
    end
  end

  @doc """
  Changeset function. Unconditionally sets the user as unconfirmed,
  generates a confirmation token and puts an expiry on it determined
  by the `:confirm_duration` config key (default one day).
  """
  def put_token(%Email{} = email), do: put_token(Changeset.cast(email, %{}, []))

  def put_token(%Changeset{} = changeset) do
    {count, unit} = config(:confirm_duration, @default_confirm_duration)
    token = Base.encode32(:crypto.strong_rand_bytes(16), padding: false)
    until = DateTime.add(DateTime.utc_now(), count, unit)

    Changeset.change(changeset,
      confirmed_at: nil,
      confirm_token: token,
      confirm_until: until
    )
  end

  @doc """
  Changeset function. Marks the user's email as confirmed and removes
  their confirmation token.
  """
  def confirm(%Email{} = email), do: confirm(Changeset.cast(email, %{}, []))

  def confirm(%Changeset{data: %Email{}} = changeset) do
    Changeset.change(changeset,
      confirm_token: nil,
      confirm_until: nil,
      confirmed_at: DateTime.utc_now()
    )
  end

  @spec should_request_or_refresh?(Email.t()) ::
          {:ok, :resend | :refresh} | {:error, binary}
  @doc "Checks whether the user should request a new confirmation token or refresh it"
  def should_request_or_refresh?(%Email{} = email, _opts \\ []) do
    cond do
      email.confirm_until &&
          DateTime.compare(email.confirm_until, DateTime.utc_now()) == :lt ->
        {:ok, :resend}

      true ->
        {:ok, :refresh}
    end
  end

  @spec may_request_confirm_email?(Email.t()) ::
          {:ok, :resend | :refresh} | {:error, binary}
  @doc "Checks whether the user should be able to request a confirm email"
  def may_request_confirm_email?(%Email{} = email, opts \\ []) do
    cond do
      not is_nil(email.confirmed_at) -> {:error, "already_confirmed"}
      not must_confirm?(opts) -> {:error, "confirmation_disabled"}
      true -> should_request_or_refresh?(email, opts)
    end
  end

  def may_confirm?(%Email{} = email, opts \\ []) do
    cond do
      not is_nil(email.confirmed_at) -> {:error, "already_confirmed"}
      is_nil(email.confirm_until) -> {:error, "no_expiry"}
      not must_confirm?(opts) -> {:error, "confirmation_disabled"}
      DateTime.compare(email.confirm_until, DateTime.utc_now()) == :gt -> :ok
      true -> {:error, :expired}
    end
  end

  @doc false
  def config(), do: Changesets.config_for(__MODULE__)
  @doc false
  def config(k, d), do: Changesets.config_for(__MODULE__, k, d)
  @doc false
  def config(opts, k, d), do: Keyword.get(opts ++ config(), k, d)

  @doc false
  def must_confirm?(opts), do: config(opts, :must_confirm?, true)
end

defmodule Bonfire.Data.Identity.Email.Migration do
  @moduledoc false
  import Ecto.Migration
  import Pointers.Migration
  alias Bonfire.Data.Identity.Email

  @email_table Email.__schema__(:source)

  # create_email_table/{0,1}

  defp make_email_table(exprs) do
    quote do
      require Pointers.Migration

      Pointers.Migration.create_mixin_table Bonfire.Data.Identity.Email do
        Ecto.Migration.add(:email_address, :text, null: false)
        Ecto.Migration.add(:confirm_token, :text)
        Ecto.Migration.add(:confirm_until, :timestamptz)
        Ecto.Migration.add(:confirmed_at, :timestamptz)
        unquote_splicing(exprs)
      end
    end
  end

  defmacro create_email_table(), do: make_email_table([])
  defmacro create_email_table(do: {_, _, body}), do: make_email_table(body)

  # drop_email_table/0

  def drop_email_table(), do: drop_mixin_table(Email)

  # create_email_address_index/{0,1}

  defp make_email_address_index(opts) do
    quote do
      Ecto.Migration.create_if_not_exists(
        Ecto.Migration.unique_index(
          unquote(@email_table),
          [:email_address],
          unquote(opts)
        )
      )
    end
  end

  defmacro create_email_address_index(opts \\ [])
  defmacro create_email_address_index(opts), do: make_email_address_index(opts)

  # drop_email_address_index/{0,1}

  def drop_email_address_index(opts \\ []) do
    drop_if_exists(unique_index(@email_table, [:email_address], opts))
  end

  # create_email_confirm_token_index/{0,1}

  defp make_email_confirm_token_index(opts) do
    quote do
      Ecto.Migration.create_if_not_exists(
        Ecto.Migration.unique_index(
          unquote(@email_table),
          [:confirm_token],
          unquote(opts)
        )
      )
    end
  end

  defmacro create_email_confirm_token_index(opts \\ [])

  defmacro create_email_confirm_token_index(opts),
    do: make_email_confirm_token_index(opts)

  # drop_email_confirm_token_index/{0,1}

  def drop_email_confirm_token_index(opts \\ []) do
    drop_if_exists(unique_index(@email_table, [:confirm_token], opts))
  end

  # migrate_email/{0,1}

  defp me(:up) do
    quote do
      unquote(make_email_table([]))
      unquote(make_email_address_index([]))
      unquote(make_email_confirm_token_index([]))
    end
  end

  defp me(:down) do
    quote do
      Bonfire.Data.Identity.Email.Migration.drop_email_confirm_token_index()
      Bonfire.Data.Identity.Email.Migration.drop_email_address_index()
      Bonfire.Data.Identity.Email.Migration.drop_email_table()
    end
  end

  defmacro migrate_email() do
    quote do
      if Ecto.Migration.direction() == :up,
        do: unquote(me(:up)),
        else: unquote(me(:down))
    end
  end

  defmacro migrate_email(dir), do: me(dir)
end
