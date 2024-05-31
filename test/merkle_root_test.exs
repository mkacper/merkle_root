defmodule MerkleRootTest do
  use ExUnit.Case

  import ExUnit.CaptureIO

  @btc_blocks_json_file_path "test/fixtures/btc_blocks.json"
  @basic_txs_file_path "test/fixtures/basic_txs.txt"

  setup_all do
    blocks_json = @btc_blocks_json_file_path |> File.read!() |> Jason.decode!()
    txs = @basic_txs_file_path |> File.read!() |> String.split()
    {:ok, btc_blocks_json: blocks_json, basic_txs: txs}
  end

  test "calculates the merkle tree root correctly for BTC transations", %{
    btc_blocks_json: blocks_json
  } do
    assert Enum.all?(blocks_json, fn %{"mrkl_root" => root_hash, "tx" => txs} ->
             path = save_txs_to_tmp_file(txs)

             capture_io(fn -> path |> opts("btc") |> MerkleRoot.main() end) ==
               "MERKLE TREE ROOT IS #{root_hash}\n"

             File.rm!(path)
           end)
  end

  test "calculates the merkle tree root correctly for BTC for a single transation", %{
    btc_blocks_json: blocks_json
  } do
    [%{"tx" => [tx | _]} | _] = blocks_json
    path = save_txs_to_tmp_file([tx])

    assert capture_io(fn -> path |> opts("btc") |> MerkleRoot.main() end) ==
             "MERKLE TREE ROOT IS #{tx["hash"]}\n"

    File.rm!(path)
  end

  test "calculates the merkle tree root for `basic` transations", %{basic_txs: txs} do
    path = save_txs_to_tmp_file(txs)
    capture_io(fn -> path |> opts("basic") |> MerkleRoot.main() end) =~ "MERKLE TREE ROOT IS "
    File.rm!(path)
  end

  test "calculates the merkle tree root for a single `basic` transations", %{basic_txs: [tx | _]} do
    path = save_txs_to_tmp_file([tx])

    capture_io(fn -> path |> opts("basic") |> MerkleRoot.main() end) =~
      "MERKLE TREE ROOT IS #{tx}\n"

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

    File.rm!(path)
  end

  test "return erros if bad input file" do
    path = save_txs_to_tmp_file([%{"hash" => :crypto.strong_rand_bytes(256)}])

    assert capture_io(fn -> path |> opts("btc") |> MerkleRoot.main() end) =~
             "unexpected error reason:"

    File.rm!(path)
  end

  # Helpers

  defp opts(path, type), do: ["--input", path, "--type", type]

  defp save_txs_to_tmp_file([tx | _] = txs) when is_map(tx) do
    txs = Enum.map(txs, & &1["hash"])
    save_txs_to_tmp_file(txs)
  end

  defp save_txs_to_tmp_file(txs) do
    txs_blob = Enum.join(txs, "\n")
    filename = 16 |> :crypto.strong_rand_bytes() |> Base.encode16(case: :lower)
    dir = System.tmp_dir!()
    tmp_file = Path.join(dir, filename)
    File.write!(tmp_file, txs_blob)
    tmp_file
  end
end
