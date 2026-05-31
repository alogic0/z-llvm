#!/usr/bin/env bash
set -euo pipefail

zig run tools/compare_opt.zig -- "$@"
