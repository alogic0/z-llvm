#!/usr/bin/env bash
set -euo pipefail

target="${TARGET:-x86_64-unknown-linux-gnu}"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

fixture="test/distribution/releasesafe_x86_64/inputs/aggregates_checked_sums.ll"
object="$tmp_dir/aggregates_checked_sums.o"
summary="$tmp_dir/aggregates_checked_sums.readelf.txt"
dump="$tmp_dir/aggregates_checked_sums.objdump.txt"
harness="$tmp_dir/aggregates_checked_sums_harness.c"
exe="$tmp_dir/aggregates_checked_sums_harness"

zig build run -- --emit=obj --target="$target" --input-limit=67108864 "$fixture" > "$object"
readelf -W -h -S -s -r "$object" > "$summary"
objdump -dr "$object" > "$dump"

rg -q 'Type:[[:space:]]+REL' "$summary"
rg -q 'Machine:[[:space:]]+Advanced Micro Devices X86-64' "$summary"
rg -q '[[:space:]]slice_sum$' "$summary"
rg -q '[[:space:]]struct_sum$' "$summary"
rg -q '[[:space:]]array_sum$' "$summary"
rg -q "R_X86_64_PLT32.*debug.FullPanic\\(\\(function 'defaultPanic'\\)\\)\\.integerOverflow - 4" "$summary"
rg -q '[[:space:]]jo[[:space:]]' "$dump"

cat > "$harness" <<'C'
#include <stdint.h>

struct Pair {
    int32_t a;
    int32_t b;
};

extern int32_t slice_sum(const int32_t *values, int64_t len);
extern int32_t struct_sum(const struct Pair *pair);
extern int32_t array_sum(int32_t a, int32_t b, int32_t c);

void panic_overflow_stub(void) __asm__("debug.FullPanic((function 'defaultPanic')).integerOverflow");
void panic_overflow_stub(void) {
    __builtin_trap();
}

int main(void) {
    int32_t values[] = { 4, -2, 9, 1 };
    struct Pair pair = { 7, 11 };

    if (slice_sum(values, 0) != 0) return 1;
    if (slice_sum(values, 4) != 12) return 2;
    if (struct_sum(&pair) != 18) return 3;
    if (array_sum(1, 2, 3) != 6) return 4;
    if (array_sum(-4, 9, 5) != 10) return 5;
    return 0;
}
C

zig cc "$harness" "$object" -o "$exe"
"$exe"
printf 'ok distribution releasesafe object aggregates_checked_sums\n'

atomics_fixture="test/distribution/releasesafe_x86_64/inputs/atomics_debug_location_checked.ll"
atomics_object="$tmp_dir/atomics_debug_location_checked.o"
atomics_summary="$tmp_dir/atomics_debug_location_checked.readelf.txt"
atomics_dump="$tmp_dir/atomics_debug_location_checked.objdump.txt"
atomics_harness="$tmp_dir/atomics_debug_location_checked_harness.c"
atomics_exe="$tmp_dir/atomics_debug_location_checked_harness"

zig build run -- --emit=obj --target="$target" --input-limit=67108864 "$atomics_fixture" > "$atomics_object"
readelf -W -h -S -s -r "$atomics_object" > "$atomics_summary"
objdump -dr "$atomics_object" > "$atomics_dump"

rg -q 'Type:[[:space:]]+REL' "$atomics_summary"
rg -q 'Machine:[[:space:]]+Advanced Micro Devices X86-64' "$atomics_summary"
rg -q '[[:space:]]debug_location$' "$atomics_summary"
rg -q "R_X86_64_PLT32.*debug.FullPanic\\(\\(function 'defaultPanic'\\)\\)\\.integerOverflow - 4" "$atomics_summary"
rg -q '[[:space:]]jo[[:space:]]' "$atomics_dump"

cat > "$atomics_harness" <<'C'
#include <stdint.h>

extern int32_t debug_location(int32_t value);

void panic_overflow_stub(void) __asm__("debug.FullPanic((function 'defaultPanic')).integerOverflow");
void panic_overflow_stub(void) {
    __builtin_trap();
}

int main(void) {
    if (debug_location(0) != 1) return 1;
    if (debug_location(41) != 42) return 2;
    if (debug_location(-2) != -1) return 3;
    return 0;
}
C

zig cc "$atomics_harness" "$atomics_object" -o "$atomics_exe"
"$atomics_exe"
printf 'ok distribution releasesafe object atomics_debug_location_checked\n'
