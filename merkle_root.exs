defmodule MerkleTree do
  def root_btc(txs) do
    txs = Enum.map(txs, &(&1 |> decode_hex() |> change_endianness()))
    calculate_root(txs, []) 
  end

  defp calculate_root([h1], []), do: :DUPA
  defp calculate_root([], [root]), do: root |> change_endianness() |> encode_hex() |> String.downcase()

  defp calculate_root([], hashes) do
    hashes_reversed = Enum.reverse(hashes)
    calculate_root(hashes_reversed, [])
  end

  defp calculate_root([h1], hashes), do: calculate_root([h1, h1], hashes)

  defp calculate_root([h1 | [h2 | rest]], hashes) do
    h1_bin = h1
    h2_bin = h2
    hash = (h1_bin <> h2_bin) |> dhash()
    calculate_root(rest, [hash | hashes])
  end

  def decode_hex(bin), do: :binary.decode_hex(bin)

  def encode_hex(bin), do: :binary.encode_hex(bin)

  def change_endianness(bin) do
    l = :binary.bin_to_list(bin)
    r = Enum.reverse(l)
    :binary.list_to_bin(r)
  end

  #def change_endianness(bin) do
  #  bin
  #  |> :binary.decode_unsigned(:little)
  #  |> :binary.encode_unsigned()
  #end

  defp dhash(bin), do: :sha256 |> :crypto.hash(bin) |> then(&:crypto.hash(:sha256, &1)) 
end
