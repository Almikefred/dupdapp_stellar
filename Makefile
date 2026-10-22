CONTRACTS_DIR := dabdub_contracts
WASM_DIR      := $(CONTRACTS_DIR)/target/wasm32v1-none/release
WASM_SIZE_LIMIT := 65536  # 64 KB
WASM_SIZE_WARN  := 52428  # 80% of 64 KB
SIZE_REPORT     := wasm-size-report.md

.PHONY: build build-optimised check-wasm-size wasm-size-report test

build:
	cd $(CONTRACTS_DIR) && cargo build --target wasm32v1-none --release

build-optimised: build
	@echo "Running wasm-opt -Oz on all contract WASMs..."
	@for wasm in $(WASM_DIR)/*.wasm; do \
		echo "  optimising $$wasm"; \
		wasm-opt -Oz --output $$wasm $$wasm; \
	done
	@echo "Done."

check-wasm-size: build-optimised
	@echo "Checking WASM sizes (limit: $(WASM_SIZE_LIMIT) bytes)..."
	@failed=0; \
	for wasm in $(WASM_DIR)/*.wasm; do \
		size=$$(wc -c < $$wasm); \
		if [ $$size -gt $(WASM_SIZE_LIMIT) ]; then \
			echo "  FAIL  $$wasm  $$size bytes  (limit $(WASM_SIZE_LIMIT))"; \
			failed=1; \
		else \
			echo "  OK    $$wasm  $$size bytes"; \
		fi; \
	done; \
	if [ $$failed -ne 0 ]; then \
		echo "One or more contracts exceed the $(WASM_SIZE_LIMIT)-byte limit."; \
		exit 1; \
	fi

# Emit a Markdown table of contract WASM sizes for posting as a PR comment.
# PREVIOUS_SIZES (optional) points to a file of "contract=bytes" lines from the
# base branch; when absent, previous size and delta are reported as n/a.
wasm-size-report: build-optimised
	@echo "Generating WASM size report -> $(SIZE_REPORT)"
	@printf '### Soroban contract WASM sizes\n\n' > $(SIZE_REPORT); \
	printf '| Contract | Current size | Previous size | Delta |\n' >> $(SIZE_REPORT); \
	printf '| --- | --- | --- | --- |\n' >> $(SIZE_REPORT); \
	for wasm in $(WASM_DIR)/*.wasm; do \
		name=$$(basename $$wasm .wasm); \
		size=$$(wc -c < $$wasm); \
		prev=""; \
		if [ -n "$(PREVIOUS_SIZES)" ] && [ -f "$(PREVIOUS_SIZES)" ]; then \
			prev=$$(grep -E "^$$name=" "$(PREVIOUS_SIZES)" | head -n1 | cut -d= -f2); \
		fi; \
		if [ -n "$$prev" ]; then \
			delta=$$((size - prev)); \
			if [ $$delta -gt 0 ]; then delta_str="+$$delta"; else delta_str="$$delta"; fi; \
			prev_str="$$prev"; \
		else \
			delta_str="n/a"; \
			prev_str="n/a"; \
		fi; \
		if [ $$size -gt $(WASM_SIZE_LIMIT) ]; then \
			printf '| %s | <span style="color:red">%s bytes</span> | %s | %s |\n' "$$name" "$$size" "$$prev_str" "$$delta_str" >> $(SIZE_REPORT); \
		elif [ $$size -gt $(WASM_SIZE_WARN) ]; then \
			printf '| %s | <span style="color:orange">%s bytes</span> | %s | %s |\n' "$$name" "$$size" "$$prev_str" "$$delta_str" >> $(SIZE_REPORT); \
		else \
			printf '| %s | %s bytes | %s | %s |\n' "$$name" "$$size" "$$prev_str" "$$delta_str" >> $(SIZE_REPORT); \
		fi; \
	done; \
	printf '\n_Budget: %s bytes (64 KB). Yellow: >80%% of budget. Red: over budget._\n' "$(WASM_SIZE_LIMIT)" >> $(SIZE_REPORT); \
	cat $(SIZE_REPORT)

test:
	cd $(CONTRACTS_DIR) && cargo test
