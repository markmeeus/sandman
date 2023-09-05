defmodule Sandman.MixProject do
  use Mix.Project

  def project do
    [
      app: :sandman,
      package: package(),
      version: "0.1.1",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      releases: [
        sandman: [
          applications: [runtime_tools: :permanent, ssl: :permanent],
          steps: [:assemble, &Desktop.Deployment.generate_installer/1]
        ],
      ],
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Sandman.Application, []},
      extra_applications: [:logger, :runtime_tools, :observer, :wx]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.7.3"},
      {:desktop, "~> 1.5"},
      {:phoenix_html, "~> 3.3"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.19.0"},
      {:floki, ">= 0.30.0", only: :test},
      {:phoenix_live_dashboard, "~> 0.8.0"},
      {:esbuild, "~> 0.7", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.2.0", runtime: Mix.env() == :dev},
      {:swoosh, "~> 1.3"},
      {:finch, "~> 0.13"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.20"},
      {:jason, "~> 1.2"},
      {:plug_cowboy, "~> 2.5"},
      {:uuid, "~> 1.1" },
      {:luerl, git: "git@github.com:markmeeus/luerl.git", ref: "6f512e9"},
      {:hammer, "~> 6.1"},
      #{:desktop_deployment, git: "git@github.com:markmeeus/deployment.git", ref: "78f6f9dd31752cfd8ac97c3ee9cd77d9a8960160", runtime: false},
      {:desktop_deployment, path: "/Users/markmeeus/Documents/projects/github/deployment"},
      {:verl, "~> 1.1"},
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "assets.setup", "assets.build"],
      test: ["test"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": [
        "tailwind default",
        "esbuild default",
        "esbuild monaco_editor"],
      "assets.deploy": [
        "tailwind default --minify",
        "esbuild default --minify",
        "esbuild monaco_editor --minify",
        "phx.digest"]
    ]
  end

  def package() do
    [
      name: "Sandman",
      name_long: "Sandman",
      description: "SandMan",
      description_long: "SandMan",
      icon: "priv/icon.png",
      # https://developer.gnome.org/menu-spec/#additional-category-registry
      category_gnome: "GNOME;WebDevelopment;",
      category_macos: "public.app-category.developer-tools",
      identifier: "io.myapp.app",
    ]
  end
end
