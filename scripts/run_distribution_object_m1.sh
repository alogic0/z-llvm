#!/usr/bin/env bash
set -euo pipefail

zig run tools/run_distribution_object_m1.zig -- "$@"
