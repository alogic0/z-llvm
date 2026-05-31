#!/usr/bin/env bash
set -euo pipefail

zig run tools/compare_codegen.zig -- --mode=asm
