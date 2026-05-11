#!/usr/bin/env bash
set -euo pipefail

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

run_opt_case() {
  local id="$1"
  local passes="$2"
  local input="$3"
  local expected="$4"
  local actual="$tmp_dir/$id.ll"

  zig build run -- --passes="$passes" "$input" > "$actual"
  diff -u "$expected" "$actual"
  printf 'ok handoff optimizer %s [%s]\n' "$id" "$passes"
}

run_opt_case \
  scalar \
  instcombine,dce \
  test/opt/inputs/instcombine_safe_scalar.ll \
  test/opt/expected/z_llvm/instcombine_safe_scalar.ll

run_opt_case \
  memory \
  dse \
  test/opt/inputs/dse_overwrite.ll \
  test/opt/expected/z_llvm/dse_overwrite.ll

run_opt_case \
  loop \
  licm \
  test/opt/inputs/licm_invariant.ll \
  test/opt/expected/z_llvm/licm_invariant.ll

run_opt_case \
  global \
  globaldce \
  test/opt/inputs/globaldce_basic.ll \
  test/opt/expected/z_llvm/globaldce_basic.ll

bash scripts/compare_codegen_asm.sh
printf 'ok handoff codegen asm smoke\n'
