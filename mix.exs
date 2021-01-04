defmodule Bonfire.Data.Identity.MixProject do
  use Mix.Project

  def project do
    [
      app: :bonfire_data_identity,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      description: "Identity-related database models (e.g. Account, User) for the bonfire ecosystem",
      homepage_url: "https://github.com/bonfire-ecosystem/bonfire_data_identity",
      source_url: "https://github.com/bonfire-ecosystem/bonfire_data_identity",
      package: [
        licenses: ["MPL 2.0"],
        links: %{
          "Repository" => "https://github.com/bonfire-ecosystem/bonfire_data_identity",
          "Hexdocs" => "https://hexdocs.pm/bonfire_data_identity",
        },
      ],
      docs: [
        main: "readme",
        extras: ["README.md"],
      ],
      deps: [
        {:pointers, "~> 0.5.1"},
#        {:pointers, path: "../../pointers"},
#        {:argon2_elixir, "~> 2.3", optional: true},
        {:pbkdf2_elixir, "~> 1.2", optional: true},
        {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      ],
    ]
  end

  def application do
    [ env: [{Bonfire.Data.Identity.Credential, hasher_module: Argon2}],
      extra_applications: [:logger],
    ]
  end

end
