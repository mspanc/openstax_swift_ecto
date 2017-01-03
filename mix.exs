defmodule OpenStax.Swift.Ecto.Mixfile do
  use Mix.Project

  def project do
    [app: :openstax_swift_ecto,
     version: "0.2.3",
     elixir: "~> 1.0",
     elixirc_paths: elixirc_paths(Mix.env),
     description: "OpenStack Swift Ecto integration",
     maintainers: ["Marcin Lewandowski"],
     licenses: ["MIT"],
     name: "OpenStax.Swift.Ecto",
     source_url: "https://github.com/mspanc/openstax_swift_ecto",
     package: package,
     preferred_cli_env: [espec: :test],
     deps: deps]
  end


  def application do
    [applications: [:openstax_swift, :file_info],
       mod: {OpenStax.Swift.Ecto, []}]
  end


  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib",]


  defp deps do
    deps(:test_dev)
  end


  defp deps(:test_dev) do
    [
      {:openstax_swift, "~> 0.2"},
      {:file_info, "~> 0.0.2"},
      {:temp, "~> 0.4"},
      {:ecto, ">= 0.0.0"},
      {:espec, "~> 0.8.17", only: :test},
      {:ex_doc, "~> 0.14.5", only: :dev},
      {:earmark, ">= 0.0.0", only: :dev}
    ]
  end


  defp package do
    [description: "OpenStack Swift Ecto integration",
     files: ["lib",  "mix.exs", "README*", "LICENSE"],
     maintainers: ["Marcin Lewandowski"],
     licenses: ["MIT"],
     links: %{github: "https://github.com/mspanc/openstax_swift_ecto"}]
  end
end
