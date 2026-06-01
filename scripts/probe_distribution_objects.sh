#!/usr/bin/env bash
set -euo pipefail

zig run tools/probe_distribution_objects.zig -- "$@"
