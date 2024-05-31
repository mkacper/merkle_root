defmodule MerkleRoot.MixProject do
  use Mix.Project

  def project do
    [
      app: :merkle_root,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: escript()
    ]
  end

  def escript() do
    opts = [main_module: MerkleRoot]

    if Mix.env() == :prod do
      [{:shebang, "#!/usr/local/bin/escript"} | opts]
    else
      opts
    end
  end

  def application do
    [
      extra_applications: [:crypto, :logger]
    ]
  end

  defp deps do
    [
      {:jason, "~> 1.4", only: :test}
    ]
  end
end
