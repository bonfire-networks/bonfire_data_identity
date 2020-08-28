defmodule CommonsPub.Accounts.MixProject do
  use Mix.Project

  def project do
    [
      app: :cpub_accounts,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
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
      # {:pointers, ">= 0.4.2", override: true},
      {:pointers, git: "https://github.com/commonspub/pointers", branch: "main"},
      # {:pointers, path: "../pointers", override: true},
    ]
  end
end
