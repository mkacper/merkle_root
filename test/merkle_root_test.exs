defmodule MerkleRootTest do
  use ExUnit.Case

  import ExUnit.CaptureIO

  @btc_blocks_json_file_path "test/fixtures/btc_blocks.json"

  setup_all do
    blocks_json = @btc_blocks_json_file_path |> File.read!() |> Jason.decode!()
    {:ok, blocks_json: blocks_json}
  end

  test "calculates the merkle tree root correctly for BTC transations", %{
    blocks_json: blocks_json
  } do
    assert Enum.all?(blocks_json, fn %{"mrkl_root" => root_hash, "tx" => txs} ->
             path = save_txs_to_tmp_file(txs)

             capture_io(fn -> path |> opts("btc") |> MerkleRoot.main() end) ==
               "MERKLE TREE ROOT IS #{root_hash}\n"

             File.rm!(path)
           end)
  end

  test "calculates the merkle tree root correctly for BTC for a single transation", %{
    blocks_json: blocks_json
  } do
    [%{"tx" => [tx | _]} | _] = blocks_json
    path = save_txs_to_tmp_file([tx])

    assert capture_io(fn -> path |> opts("btc") |> MerkleRoot.main() end) ==
             "MERKLE TREE ROOT IS #{tx["hash"]}\n"

    File.rm!(path)
  end

  test "return erros if `--input` option is missed" do
    assert capture_io(fn -> MerkleRoot.main([]) end) == "`--input` option is missing\n"
  end

  test "return erros if `--input` option points to non-existing file" do
    assert capture_io(fn -> "non/existing/path" |> opts("btc") |> MerkleRoot.main() end) ==
             "cannot read the file reason: :enoent\n"
  end

  test "return erros if `--type` option points to not supported type" do
    path = save_txs_to_tmp_file([%{"hash" => "hash"}])

    assert capture_io(fn -> path |> opts("non-supported") |> MerkleRoot.main() end) ==
             "blockchain type not supported\n"
  end

  test "return erros if bad input file" do
    path = save_txs_to_tmp_file([%{"hash" => :crypto.strong_rand_bytes(256)}])

    assert capture_io(fn -> path |> opts("btc") |> MerkleRoot.main() end) =~
             "unexpected error reason:"
  end

  # Helpers

  defp opts(path, type), do: ["--input", path, "--type", type]

  defp save_txs_to_tmp_file(txs) do
    txs = txs |> Enum.map(& &1["hash"]) |> Enum.join("\n")
    filename = 16 |> :crypto.strong_rand_bytes() |> Base.encode16(case: :lower)
    dir = System.tmp_dir!()
    tmp_file = Path.join(dir, filename)
    File.write!(tmp_file, txs)
    tmp_file
  end
end
