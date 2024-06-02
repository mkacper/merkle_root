defmodule MerkleRootTest do
  use ExUnit.Case

  import ExUnit.CaptureIO

  @btc_blocks_json_file_path "test/fixtures/btc_blocks.json"
  @basic_txs_file_path "test/fixtures/basic_txs.txt"

  setup_all do
    blocks_json = @btc_blocks_json_file_path |> File.read!() |> Jason.decode!()
    txs = @basic_txs_file_path |> File.read!() |> String.split()
    dir = create_tmp_dir!()
    on_exit(fn -> File.rm_rf!(dir) end)
    {:ok, btc_blocks_json: blocks_json, basic_txs: txs, tmp_dir: dir}
  end

  test "calculates the merkle tree root correctly for BTC transations", %{
    btc_blocks_json: blocks_json,
    tmp_dir: tmp_dir
  } do
    assert Enum.all?(blocks_json, fn %{"mrkl_root" => root_hash, "tx" => txs} ->
             # given
             path = save_txs_to_tmp_file(txs, tmp_dir)
             opts = opts(path, "btc")

             # when and then
             capture_io(fn -> MerkleRoot.main(opts) end) == "MERKLE TREE ROOT IS #{root_hash}\n"
           end)
  end

  test "calculates the merkle tree root correctly for a single BTC transation", %{
    btc_blocks_json: blocks_json,
    tmp_dir: tmp_dir
  } do
    # given
    [%{"tx" => [tx | _]} | _] = blocks_json
    path = save_txs_to_tmp_file([tx], tmp_dir)
    opts = opts(path, "btc")

    # when and then
    assert capture_io(fn -> MerkleRoot.main(opts) end) == "MERKLE TREE ROOT IS #{tx["hash"]}\n"
  end

  # It is tricky to test "basic" case as there is no reference to the correct solution
  # as in BTC case where the correct result is known from the chain block. There is
  # no point in reproducing the Merkle Tree logic in tests as there is no guarantee
  # that logic is correct. What makes sense in this case is to use property based
  # testing approach like verifying the root is 64 bytes long hex-encoded string.
  test "calculates the merkle tree root for `basic` transations", %{
    basic_txs: txs,
    tmp_dir: tmp_dir
  } do
    # given
    path = save_txs_to_tmp_file(txs, tmp_dir)
    opts = opts(path, "basic")

    # when and then
    assert <<"MERKLE TREE ROOT IS ", root::binary-size(64), "\n">> =
             capture_io(fn -> MerkleRoot.main(opts) end)

    assert {:ok, _decoded} = Base.decode16(root, case: :lower)
  end

  test "calculates the merkle tree root for a single `basic` transation", %{
    basic_txs: [tx | _],
    tmp_dir: tmp_dir
  } do
    # given
    path = save_txs_to_tmp_file([tx], tmp_dir)
    opts = opts(path, "basic")

    # when and then
    capture_io(fn -> MerkleRoot.main(opts) end) =~ "MERKLE TREE ROOT IS #{tx}\n"
  end

  test "return error if `--input` option is missing" do
    assert capture_io(fn -> MerkleRoot.main([]) end) == "`--input` option is missing\n"
  end

  test "return error if `--input` option points to non-existing file" do
    # given
    opts = opts("non/existing/path", "btc")

    # when and then
    assert capture_io(fn -> MerkleRoot.main(opts) end) == "cannot read the file reason: :enoent\n"
  end

  test "return error if `--type` option points to not supported type", %{tmp_dir: tmp_dir} do
    # given
    path = save_txs_to_tmp_file(["hash"], tmp_dir)
    opts = opts(path, "not-supported")

    # when and then
    assert capture_io(fn -> MerkleRoot.main(opts) end) == "blockchain type not supported\n"
  end

  test "return error if bad input file", %{tmp_dir: tmp_dir} do
    # given
    path = save_txs_to_tmp_file([:crypto.strong_rand_bytes(256)], tmp_dir)
    opts = opts(path, "btc")

    # when and then
    assert capture_io(fn -> MerkleRoot.main(opts) end) =~ "unexpected error reason:"
  end

  # Helpers

  defp opts(path, type), do: ["--input", path, "--type", type]

  defp save_txs_to_tmp_file([%{"hash" => _} | _] = txs, dir) do
    txs = Enum.map(txs, & &1["hash"])
    save_txs_to_tmp_file(txs, dir)
  end

  defp save_txs_to_tmp_file(txs, dir) do
    txs_blob = Enum.join(txs, "\n")
    filename = random_filename()
    tmp_file = Path.join(dir, filename)
    File.write!(tmp_file, txs_blob)
    tmp_file
  end

  defp create_tmp_dir!() do
    tmp_dir = System.tmp_dir!()
    dir_name = random_filename()
    dir_path = Path.join(tmp_dir, dir_name)
    File.mkdir!(dir_path)
    dir_path
  end

  defp random_filename(),
    do: 16 |> :crypto.strong_rand_bytes() |> Base.encode16(case: :lower)
end
