#!/usr/bin/env bash
set -euo pipefail

zig build test
bash scripts/compare_opt.sh
scripts/run_zig_corpus.sh
bash scripts/run_handoff_validation.sh
bash scripts/run_generated_scalar_diff.sh

printf 'ok readiness checks\n'
