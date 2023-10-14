Code.eval_file("mess.exs", (if File.exists?("../../lib/mix/mess.exs"), do: "../../lib/mix/"))

defmodule Bonfire.Data.Identity.MixProject do
  use Mix.Project

  def project do
    if System.get_env("AS_UMBRELLA") == "1" do
      [
        build_path: "../../_build",
        config_path: "../../config/config.exs",
        deps_path: "../../deps",
        lockfile: "../../mix.lock"
      ]
    else
      []
    end
    ++
    [
      app: :bonfire_data_identity,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      description:
        "Identity-related database models (e.g. Account, User) for the bonfire ecosystem",
      homepage_url: "https://github.com/bonfire-networks/bonfire_data_identity",
      source_url: "https://github.com/bonfire-networks/bonfire_data_identity",
      package: [
        licenses: ["MPL 2.0"],
        links: %{
          "Repository" =>
            "https://github.com/bonfire-networks/bonfire_data_identity",
          "Hexdocs" => "https://hexdocs.pm/bonfire_data_identity"
        }
      ],
      docs: [
        main: "readme",
        extras: ["README.md"]
      ],
      deps:
        Mess.deps([
          # {:pointers, path: "../../../pointers"},
          #        {:argon2_elixir, "~> 4.0", optional: true},
          {:pbkdf2_elixir, "~> 2.0", only: [:dev, :test]},
          {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
          {:nimble_totp, "~> 1.0.0", optional: true}
        ])
    ]
  end

  def application do
    [
      env: [{Bonfire.Data.Identity.Credential, hasher_module: Argon2}],
      extra_applications: [:logger]
    ]
  end
end
