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
             # given
             path = save_txs_to_tmp_file(txs)
             opts = opts(path, "btc")

             # when and then
             capture_io(fn -> MerkleRoot.main(opts) end) == "MERKLE TREE ROOT IS #{root_hash}\n"

             # cleanup
             File.rm!(path)
           end)
  end

  test "calculates the merkle tree root correctly for BTC for a single transation", %{
    btc_blocks_json: blocks_json
  } do
    # given
    [%{"tx" => [tx | _]} | _] = blocks_json
    path = save_txs_to_tmp_file([tx])
    opts = opts(path, "btc")

    # when and then
    assert capture_io(fn -> MerkleRoot.main(opts) end) == "MERKLE TREE ROOT IS #{tx["hash"]}\n"

    # cleanup
    File.rm!(path)
  end

  test "calculates the merkle tree root for `basic` transations", %{basic_txs: txs} do
    # given
    path = save_txs_to_tmp_file(txs)
    opts = opts(path, "basic")

    # when and then
    assert capture_io(fn -> MerkleRoot.main(opts) end) =~ "MERKLE TREE ROOT IS "

    # cleanup
    File.rm!(path)
  end

  test "calculates the merkle tree root for a single `basic` transations", %{basic_txs: [tx | _]} do
    # given
    path = save_txs_to_tmp_file([tx])
    opts = opts(path, "basic")

    # when and then
    capture_io(fn -> MerkleRoot.main(opts) end) =~ "MERKLE TREE ROOT IS #{tx}\n"

    # cleanup
    File.rm!(path)
  end

  test "return erros if `--input` option is missed" do
    assert capture_io(fn -> MerkleRoot.main([]) end) == "`--input` option is missing\n"
  end

  test "return erros if `--input` option points to non-existing file" do
    # given
    opts = opts("non/existing/path", "btc")

    # when and then
    assert capture_io(fn -> MerkleRoot.main(opts) end) == "cannot read the file reason: :enoent\n"
  end

  test "return erros if `--type` option points to not supported type" do
    # given
    path = save_txs_to_tmp_file(["hash"])
    opts = opts(path, "not-supported")

    # when and then
    assert capture_io(fn -> MerkleRoot.main(opts) end) == "blockchain type not supported\n"

    # cleanup
    File.rm!(path)
  end

  test "return erros if bad input file" do
    # given
    path = save_txs_to_tmp_file([:crypto.strong_rand_bytes(256)])
    opts = opts(path, "btc")

    # when and then
    assert capture_io(fn -> MerkleRoot.main(opts) end) =~ "unexpected error reason:"

    # cleanup
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
