defmodule MerkleRoot do
  @moduledoc """
  Program for calculating Merkle Tree root for a set of transations.

  Intended be run as an escript or elixir script. Available flags:
   - `--input` - required; path to the input text file that contains ordered
  hex-encoded hashes of transactions, one per line.
  - `--type` - optional; default `btc`; type of blockchain for which the Merkle
  Tree root should be calculated, supported options are `btc` or `basic`.

  For `btc` type transaction hashes bytes are reverted and double sha256 hashing
  is used.

  For `basic` type no bytes reversion is applied and single sha256 hashing is used.
  """

  @doc """
  The entry point function to be called from an escript or elixir script (.exs).
  Requires passing command line arguments in the form of `["arg1", "val1"]`.
  See moduledoc for supported arguments.
  """
  def main(args) do
    opts = parse_options(args)

    with {:input, input} when not is_nil(input) <- {:input, Keyword.get(opts, :input)},
         {:type, type} <- {:type, Keyword.get(opts, :type, "btc")},
         {:file, {:ok, txs_blob}} <- {:file, File.read(input)},
         txs <- String.split(txs_blob),
         {:ok, root} <- root(txs, type) do
      IO.puts("MERKLE TREE ROOT IS #{root}")
    else
      {:input, nil} ->
        IO.puts("`--input` option is missing")

      {:file, {:error, reason}} ->
        IO.puts("cannot read the file reason: #{inspect(reason)}")

      {:error, :not_supported} ->
        IO.puts("blockchain type not supported")
    end
  rescue
    error ->
      reason = Exception.format(:error, error, __STACKTRACE__)
      IO.puts("unexpected error reason: #{inspect(reason)}")
  end

  # Internals

  defp root(txs, "btc"), do: {:ok, root_btc(txs)}
  defp root(txs, "basic"), do: {:ok, root_basic(txs)}
  defp root(_txs, _type), do: {:error, :not_supported}

  defp root_btc([tx]), do: tx

  defp root_btc(txs),
    do:
      calculate_root(txs, _level_hashes = [], _height = 0,
        hash_fun: &dhash(&1),
        reverse_byte_order?: true
      )

  defp root_basic([tx]), do: tx

  defp root_basic(txs),
    do:
      calculate_root(txs, _level_hashes = [], _height = 0,
        hash_fun: &hash(&1),
        reverse_byte_order?: false
      )

  defp calculate_root([], [root], _height, opts),
    do: root |> maybe_reverse_bytes(opts) |> encode_hex()

  defp calculate_root([], hashes, height, opts) do
    hashes
    |> Enum.reverse()
    |> calculate_root([], height + 1, opts)
  end

  defp calculate_root([h1], hashes, height, opts),
    do: calculate_root([h1, h1], hashes, height, opts)

  defp calculate_root([h1 | [h2 | rest]], hashes, height = 0, opts) do
    h1_bin = h1 |> decode_hex() |> maybe_reverse_bytes(opts)
    h2_bin = h2 |> decode_hex() |> maybe_reverse_bytes(opts)
    calculate_root(rest, [opts[:hash_fun].(h1_bin <> h2_bin) | hashes], height, opts)
  end

  defp calculate_root([h1 | [h2 | rest]], hashes, height, opts),
    do: calculate_root(rest, [opts[:hash_fun].(h1 <> h2) | hashes], height, opts)

  # Utils

  defp parse_options(args) do
    {opts, _, _} = OptionParser.parse(args, strict: [input: :string, type: :string])
    opts
  end

  defp decode_hex(bin), do: :binary.decode_hex(bin)

  defp encode_hex(bin), do: bin |> :binary.encode_hex() |> String.downcase()

  defp maybe_reverse_bytes(bytes, opts) do
    (opts[:reverse_byte_order?] && reverse_bytes(bytes)) || bytes
  end

  defp reverse_bytes(bin) do
    bin
    |> :binary.bin_to_list()
    |> Enum.reverse()
    |> :binary.list_to_bin()
  end

  defp dhash(bin), do: bin |> hash() |> hash()

  defp hash(bin), do: :crypto.hash(:sha256, bin)
end
