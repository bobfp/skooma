defmodule Skooma.Mixfile do
  use Mix.Project

  def project do
    [
      app: :skooma,
      version: "0.2.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps(),
      description: "Data structure validator for elixir",
      package: [
        name: "skooma",
        licenses: ["MIT"],
        maintainers: ["bcoop713@gmail.com"],
        links: %{"Github" => "https://github.com/bcoop713/skooma"}
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:moonsugar, "~> 0.1.0"}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
    ]
  end
end
