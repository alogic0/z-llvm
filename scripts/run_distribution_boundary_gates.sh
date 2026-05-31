#!/usr/bin/env bash
set -euo pipefail

printf 'distribution boundary gates\n'

bash scripts/run_distribution_linker_boundary.sh
bash scripts/run_distribution_releasesmall_boundary_m3.sh
bash scripts/run_distribution_debug_unwind_boundary.sh
TARGET=x86_64-unknown-linux-musl bash scripts/run_distribution_debug_unwind_boundary.sh
bash scripts/run_distribution_aarch64_object_boundary.sh

printf 'ok distribution boundary gates\n'
