#!/usr/bin/env bash
set -euo pipefail

zig run tools/lint_zig_ir_manifest.zig -- "$@"
