# MerkleRoot

Program for calculating Merkle Tree Root. Can be run directly as an escript
executable or via Docker.

Available flags:
   - `--input` - required; path to the input text file that contains ordered
  hex-encoded hashes of transactions, one per line.
  - `--type` - optional; default `btc`; type of blockchain for which the Merkle
  Tree root should be calculated, supported options are `btc` or `basic`.

For `btc` type transaction hashes bytes are reverted and double sha256 hashing
is used.

For `basic` type no bytes reversion is applied and single sha256 hashing is used.

## Requirements

* Elixir 1.14.0
* Erlang 25.1

## Running using `escript`

This method requires meeting requirements regarding having Erlang and
Elixir installed.

Run the following commands:

```bash
cd <project-root>
make escript-build
./merkle_root --input <path-to-input-file> --type <type>
```

> NOTE: make sure the produced escript has executable rights (`chmod +x merkle_root`)

## Running using `docker`

Run the following commands:

```bash
cd <project-root>
make docker-build
# make sure to use an absolute path to a file e.g. `INPUT_FILE_PATH="$(pwd)/txs.txt"`
INPUT_FILE_PATH=<path-to-input-file> TYPE=<type> make docker-run
```

> NOTE: Tested on MacOS with Docker version 20.10.17, build 100c701

## Preparing sample transactions input file

In order to prepare a sample input file test fixtures can be used.

For `btc` type one could use the following command:
```bash
cd <project-root>
cat test/fixtures/btc_blocks.json | jq '.[0]' | jq .tx | jq '.[].hash' | sed 's/"//g' > sample_txs.txt
```

For `basic` type one could just use
`<project-root>/test/fixtures/basic_txs.txt`.
