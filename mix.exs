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
    [main_module: MerkleRoot, embed_elixir: true, shebang: "#!/usr/local/bin/escript"]
  end

  def application do
    [
      extra_applications: [:crypto, :logger]
    ]
  end

  defp deps do
    []
  end
end
