#!/usr/bin/env bash
set -euo pipefail

zig run tools/capture_zig_ir.zig -- "$@"
