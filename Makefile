.PHONY: escript-build docker-build docker-run

escript-build:
	mix escript.build

docker-build:
	docker build . --tag merkle_root

docker-run:
	docker run -v ${INPUT_FILE_PATH}:/app/txs -e TYPE="${TYPE}" merkle_root:latest
