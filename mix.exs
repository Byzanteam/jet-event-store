defmodule JetEventStore.MixProject do
  use Mix.Project

  def project do
    [
      app: :jet_event_store,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      dialyzer: dialyzer(),
      aliases: aliases(),
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
      {:commanded, "~> 1.4", optional: true},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:ecto, "~> 3.8"},
      {:ex_doc, "~> 0.28.4", only: :dev},
      {:typed_struct, "~> 0.3.0"}
    ]
  end

  defp aliases do
    [
      "code.check": ["format --check-formatted", "credo --strict", "dialyzer"]
    ]
  end

  defp dialyzer do
    [
      plt_add_apps: [:commanded],
      plt_add_deps: :app_tree,
      plt_file: {:no_warn, "priv/plts/jet_event_store.plt"}
    ]
  end
end
