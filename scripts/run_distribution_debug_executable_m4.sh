#!/usr/bin/env bash
set -euo pipefail

target="${TARGET:-x86_64-unknown-linux-gnu}"
case "$target" in
    x86_64-unknown-linux-gnu) cc_target="${CC_TARGET:-x86_64-linux-gnu}" ;;
    x86_64-unknown-linux-musl) cc_target="${CC_TARGET:-x86_64-linux-musl}" ;;
    *) cc_target="${CC_TARGET:-$target}" ;;
esac
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

mathtest_fixture="test/distribution/debug_x86_64/inputs/shared_library_mathtest_add_o0.ll"
mathtest_object="$tmp_dir/shared_library_mathtest_add_o0.o"
mathtest_harness="$tmp_dir/shared_library_mathtest_add_o0_harness.c"
mathtest_panic_stub="$tmp_dir/debug_panic_stub.s"
mathtest_exe="$tmp_dir/shared_library_mathtest_add_o0_harness"

zig build run -- --emit=obj --target="$target" --input-limit=67108864 "$mathtest_fixture" > "$mathtest_object"

cat > "$mathtest_harness" <<'C'
extern int add(int a, int b);

int main(void) {
    if (add(40, 2) != 42) return 1;
    if (add(-7, 9) != 2) return 2;
    return 0;
}
C

cat > "$mathtest_panic_stub" <<'ASM'
.text
.globl "debug.FullPanic((function 'defaultPanic')).integerOverflow"
.type "debug.FullPanic((function 'defaultPanic')).integerOverflow", @function
"debug.FullPanic((function 'defaultPanic')).integerOverflow":
  ud2
ASM

zig cc -target "$cc_target" "$mathtest_harness" "$mathtest_panic_stub" "$mathtest_object" -o "$mathtest_exe"
"$mathtest_exe"
printf 'ok distribution debug executable shared_library_mathtest_add_o0\n'
