.PHONY: clean build-node start-reth reth-and-node-ci test-ci build-precompiles copy-precompile

current_dir := ${CURDIR}
era_test_node_base_path := $(current_dir)/.test-node-subtree
era_test_node := $(era_test_node_base_path)/target/release/era_test_node
era_test_node_makefile := $(era_test_node_base_path)/Makefile
precompile_dst_path := $(era_test_node_base_path)/etc/system-contracts/contracts/precompiles
era_test_node_src_files = $(shell find $(era_test_node_base_path)/src -name "*.rs")

precompiles_source = $(wildcard $(current_dir)/precompiles/*.yul)
precompiles_dst = $(patsubst $(current_dir)/precompiles/%, $(precompile_dst_path)/%, $(precompiles_source))

run-node: build-contracts $(era_test_node)
	$(era_test_node) --show-calls=all --resolve-hashes --show-gas-details=all run

# test node needs contracts for include bytes directive
# source files are obtained just to recompile if there are changes, and located with a find
$(era_test_node): $(era_test_node_makefile) $(era_test_node_src_files) $(precompiles_dst)
	cd $(era_test_node_base_path) && make rust-build

## precompile source is added just to avoid recompiling if they haven't changed
build-contracts: $(precompiles_source)
	cp precompiles/*.yul $(precompile_dst_path) && cd $(era_test_node_base_path) && make build-contracts

run-node-light: $(era_test_node) $(precompiles_dst)
	$(era_test_node) run

# Node Commands
update-node: era_test_node
	cd $(era_test_node_base_path) && make rust-build

start-reth:
	docker compose down
	docker compose up -d --wait reth

test: start-reth
	cd tests && \
	cargo test ${PRECOMPILE}

run-node-ci: build-contracts $(era_test_node)
	$(era_test_node) --show-calls=all --resolve-hashes --show-gas-details=all run > era_node.log &

test-ci: run-node-ci start-reth
	sleep 1
	cd tests && cargo test

docs:
	cd docs && mdbook serve --open

clean:
	# for file in $(shell ls ./precompiles/*.yul | grep -o '[^/]+(?=\.yul)'); do \
	# 	rm -f $(era_test_node_base_path)/src/deps/contracts/$${file}.yul.zbin; \
	# done
	cd .test-node-subtree && make clean-contracts

check-git-ignore:
	cd precompiles
	$(shell ./precompiles/git_ignore_check.sh)
