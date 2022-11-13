defmodule Eversign.MixProject do
  use Mix.Project
  @project_url "https://github.com/fbettag/eversign.ex"

  def project do
    [
      app: :eversign,
      version: "0.1.0",
      elixir: "~> 1.13",
      source_url: @project_url,
      homepage_url: @project_url,
      name: "eversign.com API for digitally signing PDF documents",
      description: "Implements the affordable document signing API provided by eversign.com",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      package: package(),
      aliases: aliases(),
      deps: deps(),
      dialyzer: [
        plt_add_deps: :apps_direct
      ]
    ]
  end

  defp package do
    [
      name: "eversign",
      maintainers: ["Franz Bettag"],
      licenses: ["MIT"],
      links: %{"GitHub" => @project_url},
      files: ~w(lib LICENSE README.md mix.exs)
    ]
  end

  defp aliases do
    [credo: "credo -a --strict"]
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
      {:tesla, "~> 1.4"},
      {:poison, "~> 3.1"},
      {:phoenix_html, "~> 3.0"},
      {:ex_doc, "~> 0.19", only: :dev},
      {:doctor, "~> 0.17.0", only: :dev},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:credo, github: "rrrene/credo", only: [:dev, :test]},
      {:git_hooks, "~> 0.4.0", only: [:test, :dev], runtime: false}
    ]
  end
end
