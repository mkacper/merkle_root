defmodule MerkleRoot do
  @moduledoc """
  Program for calculating Merkle Tree root for a set of transations.

  Intended be run as an escript or elixir script. Available flags:
   - `--input` - required; path to the input text file that contains ordered
  hex-encoded hashes of transactions, one per line.
  - `--type` - optional; default `btc`; type of blockchain for which the Merkle
  Tree root should be calculated, supported options are `btc` or `basic`.

  For `btc` type transaction hashes bytes are reversed and double sha256 hashing
  is used.

  For `basic` type no bytes reversion is applied and single sha256 hashing is used.
  """

  @doc """
  The entry point function to be called from an escript or elixir script (.exs).
  Requires passing command line arguments in the form of `["arg1", "val1"]`.
  See moduledoc for supported arguments.

  Example usage:

  ```
  iex> MerkleRoot.main(["--input", "sample_txs.txs", "--type", "btc"])
  MERKLE TREE ROOT IS 414a0fd551335d14b543c685fa7d3edac15579dac578218bf0253b36724e35d0
  :ok
  ```
  """
  def main(args) do
    opts = parse_options(args)

    with {:ok, input} <- get_opt(opts, :input),
         {:ok, type} <- get_opt(opts, :type, "btc"),
         {:ok, txs} <- read_txs_from_file(input),
         {:ok, root} <- root(txs, type),
         :ok <- IO.puts("MERKLE TREE ROOT IS #{root}") do
      :ok
    else
      {:error, reason} ->
        msg = parse_error(reason)
        IO.puts(msg)
    end
  rescue
    error ->
      reason = Exception.format(:error, error, __STACKTRACE__)
      msg = parse_error({:unexpected, reason})
      IO.puts(msg)
  end

  # Internals

  defp root(txs, "btc"), do: {:ok, root_btc(txs)}
  defp root(txs, "basic"), do: {:ok, root_basic(txs)}
  defp root(_txs, type), do: {:error, {:type_not_supported, type}}

  defp root_btc([tx]), do: tx

  defp root_btc(txs),
    do:
      calculate_root(txs, _level_hashes = [], _height = 0,
        hash_fun: &double_hash(&1),
        reverse_byte_order?: true
      )

  defp root_basic([tx]), do: tx

  defp root_basic(txs),
    do:
      calculate_root(txs, _level_hashes = [], _height = 0,
        hash_fun: &hash(&1),
        reverse_byte_order?: false
      )

  # single hash left in a level - the root is reached
  defp calculate_root([], [root], _height, opts),
    do: root |> maybe_reverse_bytes(opts) |> encode_hex()

  # no hashes left - next level is calculated
  defp calculate_root([], hashes, height, opts) do
    hashes
    |> Enum.reverse()
    |> calculate_root([], height + 1, opts)
  end

  # single hash left - should be hashed with itself
  defp calculate_root([h1], hashes, height, opts),
    do: calculate_root([h1, h1], hashes, height, opts)

  # for "the most bottom" level hex decoding should happen
  # additionaly, for BTC bytes should be reversed
  #
  # NOTE: These operations could be performed in the higher level `root/2`
  # function depending on `type` but it would require additional iteration over
  # list of hashes hence doing it here to avoid that extra cost.
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

  defp get_opt(options, opt, default \\ nil) do
    case Keyword.get(options, opt, default) do
      nil -> {:error, {:option_not_found, opt}}
      opt -> {:ok, opt}
    end
  end

  defp read_txs_from_file(path) do
    case File.read(path) do
      {:ok, blob} ->
        {:ok, String.split(blob)}

      {:error, reason} ->
        {:error, {:cannot_read_file, reason}}
    end
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

  defp double_hash(bin), do: bin |> hash() |> hash()

  defp hash(bin), do: :crypto.hash(:sha256, bin)

  defp parse_error({:option_not_found, :input}), do: "`--input` option is missing"

  defp parse_error({:cannot_read_file, reason}),
    do: "cannot read the file reason: #{inspect(reason)}"

  defp parse_error({:type_not_supported, type}),
    do: "`--type` option does not support `#{type}` value"

  defp parse_error({:unexpected, reason}), do: "unexpected error reason: #{inspect(reason)}"
end
