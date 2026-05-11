#!/usr/bin/env bash
set -euo pipefail

opt_bin="${OPT_BIN:-opt-22}"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

write_case() {
  local id="$1"
  local op="$2"
  local rhs="$3"
  local path="$tmp_dir/$id.ll"

  cat > "$path" <<CASE
define i32 @$id(i32 %x) {
entry:
  %y = $op i32 %x, $rhs
  ret i32 %y
}
CASE
}

run_equivalent_case() {
  local id="$1"
  local passes="$2"
  local path="$tmp_dir/$id.ll"
  local z_raw="$tmp_dir/$id.z.ll"
  local z_norm="$tmp_dir/$id.z.norm.ll"
  local llvm_raw="$tmp_dir/$id.llvm.ll"
  local llvm_norm="$tmp_dir/$id.llvm.norm.ll"

  zig build run -- --passes="$passes" "$path" > "$z_raw"
  "$opt_bin" -passes="$passes" "$path" -S -o "$llvm_raw"
  zig run src/normalize_cli.zig -- "$z_raw" > "$z_norm"
  zig run src/normalize_cli.zig -- "$llvm_raw" > "$llvm_norm"
  diff -u "$llvm_norm" "$z_norm"
  printf 'ok generated scalar %s [%s]\n' "$id" "$passes"
}

write_case gen_add_zero add 0
write_case gen_sub_zero sub 0
write_case gen_mul_one mul 1
write_case gen_and_allones and -1
write_case gen_or_zero or 0
write_case gen_xor_zero xor 0

for id in gen_add_zero gen_sub_zero gen_mul_one gen_and_allones gen_or_zero gen_xor_zero; do
  run_equivalent_case "$id" "instcombine,dce"
done

cat > "$tmp_dir/unsupported_vector.ll" <<'CASE'
define <vscale x 2 x i32> @bad(<vscale x 2 x i32> %x) {
entry:
  ret <vscale x 2 x i32> %x
}
CASE

if zig build run -- "$tmp_dir/unsupported_vector.ll" > "$tmp_dir/unsupported_vector.out" 2> "$tmp_dir/unsupported_vector.err"; then
  printf 'expected unsupported vector case to fail\n' >&2
  exit 1
fi
printf 'ok generated negative unsupported_vector\n'

cat > "$tmp_dir/unsupported_atomic_syncscope.ll" <<'CASE'
define i32 @bad(ptr %p) {
entry:
  %v = atomicrmw add ptr %p, i32 1 syncscope("singlethread") monotonic
  ret i32 %v
}
CASE

if zig build run -- "$tmp_dir/unsupported_atomic_syncscope.ll" > "$tmp_dir/unsupported_atomic_syncscope.out" 2> "$tmp_dir/unsupported_atomic_syncscope.err"; then
  printf 'expected unsupported atomic syncscope case to fail\n' >&2
  exit 1
fi
printf 'ok generated negative unsupported_atomic_syncscope\n'

if command -v lli-22 >/dev/null 2>&1; then
  cat > "$tmp_dir/execute_main.ll" <<'CASE'
define i32 @main() {
entry:
  %x = add i32 42, 0
  ret i32 %x
}
CASE
  zig build run -- --passes=instcombine,dce "$tmp_dir/execute_main.ll" > "$tmp_dir/execute_main.opt.ll"
  set +e
  lli-22 "$tmp_dir/execute_main.opt.ll"
  status="$?"
  set -e
  if [[ "$status" != "42" ]]; then
    printf 'expected lli-22 exit status 42, got %s\n' "$status" >&2
    exit 1
  fi
  printf 'ok generated execution lli-22\n'
else
  printf 'skip generated execution lli-22 unavailable\n'
fi
