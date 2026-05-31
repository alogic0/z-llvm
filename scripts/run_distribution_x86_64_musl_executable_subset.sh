#!/usr/bin/env bash
set -euo pipefail

target="${TARGET:-x86_64-unknown-linux-musl}"
export TARGET="$target"

printf 'distribution x86_64 musl executable subset target=%s\n' "$target"

bash scripts/run_distribution_executable_m1.sh
bash scripts/run_distribution_debug_executable_m4.sh

printf 'ok distribution x86_64 musl executable subset\n'
