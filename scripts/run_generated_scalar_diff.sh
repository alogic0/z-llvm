#!/usr/bin/env bash
set -euo pipefail

zig run tools/run_generated_scalar_diff.zig
