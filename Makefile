# Makefile for common development tasks

.PHONY: build build-optimised check-wasm-size test verify-deployment lint lint-clippy lint-fmt lint-audit

# Run all lint checks in sequence. Stops on the first failure with a clear
# message identifying which check failed.
lint:
	@echo "==> [1/3] Running clippy..."
	@$(MAKE) --no-print-directory lint-clippy || { echo "ERROR: clippy check failed. Run 'cargo clippy --all-targets --all-features -- -D warnings' to see details." >&2; exit 1; }
	@echo "==> [2/3] Running fmt check..."
	@$(MAKE) --no-print-directory lint-fmt || { echo "ERROR: fmt check failed. Run 'cargo fmt --all' to fix formatting." >&2; exit 1; }
	@echo "==> [3/3] Running audit..."
	@$(MAKE) --no-print-directory lint-audit || { echo "ERROR: audit check failed. Run 'cargo audit' to see details." >&2; exit 1; }
	@echo "==> All lint checks passed."

lint-clippy:
	cargo clippy --all-targets --all-features -- -D warnings

lint-fmt:
	cargo fmt --all -- --check

lint-audit:
	cargo audit

test:
	cd $(CONTRACTS_DIR) && cargo test

verify-deployment:
	bash scripts/verify-deployment.sh
