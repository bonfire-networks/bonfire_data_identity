Code.eval_file("mess.exs")
defmodule Bonfire.Data.Identity.MixProject do
  use Mix.Project

  def project do
    [
      app: :bonfire_data_identity,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      description: "Accounts, Users, related models for bonfire-ecosystem",
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
      deps: Mess.deps [ {:ex_doc, ">= 0.0.0", only: :dev, runtime: false} ]
    ]
  end

  def application, do: [extra_applications: [:logger]]

end
