#!/usr/bin/env bash
set -euo pipefail

target="${TARGET:-x86_64-unknown-linux-musl}"
export TARGET="$target"

printf 'distribution x86_64 musl object subset target=%s\n' "$target"

bash scripts/run_distribution_object_m1.sh
bash scripts/run_distribution_releasesafe_object_m2.sh
bash scripts/run_distribution_releasesmall_object_m3.sh
bash scripts/run_distribution_debug_object_m4.sh

printf 'ok distribution x86_64 musl object subset\n'
