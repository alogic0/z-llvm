#!/usr/bin/env bash
set -euo pipefail

opt_bin="${OPT_BIN:-opt-22}"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

fixtures=(
  "instcombine:instcombine:test/opt/inputs/instcombine.ll"
  "dce:dce:test/opt/inputs/dce.ll"
  "dce:dce:test/opt/inputs/memory_dce.ll"
  "simplifycfg:simplifycfg:test/opt/inputs/simplifycfg.ll"
  "mem2reg:mem2reg:test/opt/inputs/mem2reg.ll"
)

for fixture in "${fixtures[@]}"; do
  IFS=: read -r z_pass llvm_pass input_path <<< "$fixture"
  name="$(basename "$input_path" .ll)"

  z_raw="$tmp_dir/$name.z.raw.ll"
  z_norm="$tmp_dir/$name.z.norm.ll"
  llvm_raw="$tmp_dir/$name.llvm.raw.ll"
  llvm_norm="$tmp_dir/$name.llvm.norm.ll"

  zig build run -- --passes="$z_pass" "$input_path" > "$z_raw"
  "$opt_bin" -passes="$llvm_pass" "$input_path" -S -o "$llvm_raw"

  zig run src/normalize_cli.zig -- "$z_raw" > "$z_norm"
  zig run src/normalize_cli.zig -- "$llvm_raw" > "$llvm_norm"

  diff -u "$llvm_norm" "$z_norm"
  printf 'ok %s\n' "$input_path"
done
