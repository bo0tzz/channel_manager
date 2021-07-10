defmodule ChannelManager.MixProject do
  use Mix.Project

  def project do
    [
      app: :channel_manager,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {ChannelManager.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_gram, "~> 0.21"},
      {:tesla, "~> 1.2"},
      {:hackney, "~> 1.12"},
      {:jason, ">= 1.0.0"},
      {:quantum, "~> 3.0"},
      {:yaml_elixir, "~> 2.7"},
      {:date_time_parser, "~> 1.1"},
      {:elixir_feed_parser, "~> 2.1"},
      {:typed_struct, "~> 0.2.1", runtime: false}
    ]
  end
end
