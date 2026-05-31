#!/usr/bin/env bash
set -euo pipefail

zig build >/dev/null
zig run tools/probe_distribution_objects.zig -- "$@"
