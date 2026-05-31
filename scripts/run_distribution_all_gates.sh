#!/usr/bin/env bash
set -euo pipefail

target="${TARGET:-x86_64-unknown-linux-gnu}"
export TARGET="$target"

printf 'distribution all gates target=%s\n' "$target"

bash scripts/run_distribution_no_llvm_codegen_subset.sh
bash scripts/run_distribution_boundary_gates.sh

printf 'ok distribution all gates\n'
