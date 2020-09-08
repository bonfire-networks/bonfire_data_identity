defmodule CommonsPub.Accounts.MixProject do
  use Mix.Project

  def project do
    [
      app: :cpub_accounts,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      description: "Account-related models for commonspub",
      homepage_url: "https://github.com/commonspub/cpub_accounts",
      source_url: "https://github.com/commonspub/cpub_accounts",
      package: [
        licenses: ["MPL 2.0"],
        links: %{
          "Repository" => "https://github.com/commonspub/cpub_accounts",
          "Hexdocs" => "https://hexdocs.pm/cpub_accounts",
        },
      ],
      docs: [
        main: "readme", # The first page to display from the docs 
        extras: ["README.md"], # extra pages to include
      ],
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:pointers, "~> 0.5.1"},
      # {:pointers, git: "https://github.com/commonspub/pointers", branch: "main"},
      # {:pointers, path: "../pointers", override: true},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
    ]
  end
end
