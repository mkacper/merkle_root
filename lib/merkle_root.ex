defmodule MerkleRoot do
  @moduledoc """
  Documentation for `MerkleRoot`.
  """
  def main(args) do
    opts = parse_options(args)
    path_to_file = Keyword.fetch!(opts, :input)
    blockchain_type = Keyword.get(opts, :type, "btc")
    txs = path_to_file |> File.read!() |> String.split()

    case blockchain_type do
      "btc" ->
        root = root_btc(txs)
        IO.puts("MERKLE TREE ROOT IS #{root}")

      _other ->
        raise "Blockchain not supported!"
    end
  end

  # Internal

  defp parse_options(args) do
    {opts, _, _} = OptionParser.parse(args, strict: [input: :string, type: :string])
    opts
  end

  defp root_btc(txs), do: calculate_root(txs, _level_hashes = [], _height = 0) 

  defp calculate_root([], [root], _height),
    do: root |> reverse_bytes() |> encode_hex()

  defp calculate_root([], hashes, height) do
    hashes
    |> Enum.reverse()
    |> calculate_root([], height + 1)
  end

  defp calculate_root([h1], hashes, height), do: calculate_root([h1, h1], hashes, height)

  defp calculate_root([h1 | [h2 | rest]], hashes, height = 0) do
    h1_bin = h1 |> decode_hex() |> reverse_bytes()
    h2_bin = h2 |> decode_hex() |> reverse_bytes()
    calculate_root(rest, [dhash(h1_bin <> h2_bin) | hashes], height)
  end

  defp calculate_root([h1 | [h2 | rest]], hashes, height),
    do: calculate_root(rest, [dhash(h1 <> h2) | hashes], height)

  defp decode_hex(bin), do: :binary.decode_hex(bin)

  defp encode_hex(bin), do: bin |> :binary.encode_hex() |> String.downcase()

  defp reverse_bytes(bin) do
    bin
    |> :binary.bin_to_list()
    |> Enum.reverse()
    |> :binary.list_to_bin()
  end

  defp dhash(bin), do: bin |> hash() |> hash() 

  defp hash(bin), do: :crypto.hash(:sha256, bin)
end
