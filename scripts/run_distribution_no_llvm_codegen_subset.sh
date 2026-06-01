#!/usr/bin/env bash
set -euo pipefail

zig run tools/run_distribution_no_llvm_codegen_subset.zig
