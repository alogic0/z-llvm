#!/usr/bin/env bash
set -euo pipefail

zig run tools/run_distribution_x86_64_musl_subset.zig -- --mode=object
