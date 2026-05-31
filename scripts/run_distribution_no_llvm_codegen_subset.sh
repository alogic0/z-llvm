#!/usr/bin/env bash
set -euo pipefail

target="${TARGET:-x86_64-unknown-linux-gnu}"
export TARGET="$target"

printf 'distribution no-LLVM-codegen subset target=%s\n' "$target"

bash scripts/run_distribution_object_m1.sh
bash scripts/run_distribution_executable_m1.sh
bash scripts/run_distribution_releasesafe_object_m2.sh
bash scripts/run_distribution_releasesmall_object_m3.sh
bash scripts/run_distribution_debug_object_m4.sh
bash scripts/run_handoff_validation.sh

printf 'ok distribution no-LLVM-codegen subset\n'
