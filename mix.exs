Code.eval_file("mess.exs")
defmodule Bonfire.Data.Auth.MixProject do
  use Mix.Project

  def project do
    [
      app: :bonfire_data_auth,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      description: "Account-related models for bonfire-ecosystem",
      homepage_url: "https://github.com/bonfire-ecosystem/bonfire_data_auth",
      source_url: "https://github.com/bonfire-ecosystem/bonfire_data_auth",
      package: [
        licenses: ["MPL 2.0"],
        links: %{
          "Repository" => "https://github.com/bonfire-ecosystem/bonfire_data_auth",
          "Hexdocs" => "https://hexdocs.pm/bonfire_data_auth",
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
