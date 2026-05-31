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

control_flow_fixture="test/distribution/releasesafe_x86_64/inputs/control_flow_calls_checked.ll"
control_flow_object="$tmp_dir/control_flow_calls_checked.o"
control_flow_summary="$tmp_dir/control_flow_calls_checked.readelf.txt"
control_flow_dump="$tmp_dir/control_flow_calls_checked.objdump.txt"
control_flow_harness="$tmp_dir/control_flow_calls_checked_harness.c"
control_flow_exe="$tmp_dir/control_flow_calls_checked_harness"

zig build run -- --emit=obj --target="$target" --input-limit=67108864 "$control_flow_fixture" > "$control_flow_object"
readelf -W -h -S -s -r "$control_flow_object" > "$control_flow_summary"
objdump -dr "$control_flow_object" > "$control_flow_dump"

rg -q 'Type:[[:space:]]+REL' "$control_flow_summary"
rg -q 'Machine:[[:space:]]+Advanced Micro Devices X86-64' "$control_flow_summary"
rg -q '[[:space:]]loop_sum$' "$control_flow_summary"
rg -q '[[:space:]]call_chain$' "$control_flow_summary"
rg -q "R_X86_64_PLT32.*debug.FullPanic\\(\\(function 'defaultPanic'\\)\\)\\.integerOverflow - 4" "$control_flow_summary"
rg -q "R_X86_64_PLT32.*debug.FullPanic\\(\\(function 'defaultPanic'\\)\\)\\.integerOutOfBounds - 4" "$control_flow_summary"
rg -q '[[:space:]]jo[[:space:]]' "$control_flow_dump"
rg -q '[[:space:]]js[[:space:]]' "$control_flow_dump"

cat > "$control_flow_harness" <<'C'
#include <stdint.h>

extern int32_t loop_sum(uint32_t limit);
extern int32_t call_chain(int32_t value);

void panic_overflow_stub(void) __asm__("debug.FullPanic((function 'defaultPanic')).integerOverflow");
void panic_overflow_stub(void) {
    __builtin_trap();
}

void panic_out_of_bounds_stub(void) __asm__("debug.FullPanic((function 'defaultPanic')).integerOutOfBounds");
void panic_out_of_bounds_stub(void) {
    __builtin_trap();
}

int main(void) {
    if (loop_sum(0) != 0) return 1;
    if (loop_sum(1) != 0) return 2;
    if (loop_sum(5) != 10) return 3;
    if (loop_sum(13) != 78) return 4;
    if (call_chain(0) != 1) return 5;
    if (call_chain(5) != 11) return 6;
    if (call_chain(17) != 35) return 7;
    return 0;
}
C

zig cc "$control_flow_harness" "$control_flow_object" -o "$control_flow_exe"
"$control_flow_exe"
printf 'ok distribution releasesafe object control_flow_calls_checked\n'

error_switch_fixture="test/distribution/releasesafe_x86_64/inputs/error_switch_select.ll"
error_switch_object="$tmp_dir/error_switch_select.o"
error_switch_summary="$tmp_dir/error_switch_select.readelf.txt"
error_switch_dump="$tmp_dir/error_switch_select.objdump.txt"
error_switch_harness="$tmp_dir/error_switch_select_harness.c"
error_switch_exe="$tmp_dir/error_switch_select_harness"

zig build run -- --emit=obj --target="$target" --input-limit=67108864 "$error_switch_fixture" > "$error_switch_object"
readelf -W -h -S -s -r "$error_switch_object" > "$error_switch_summary"
objdump -dr "$error_switch_object" > "$error_switch_dump"

rg -q 'Type:[[:space:]]+REL' "$error_switch_summary"
rg -q 'Machine:[[:space:]]+Advanced Micro Devices X86-64' "$error_switch_summary"
rg -q '[[:space:]]error_switch$' "$error_switch_summary"
rg -q 'cmp[[:space:]].*0x0' "$error_switch_dump"
rg -q 'cmp[[:space:]].*0x1' "$error_switch_dump"

cat > "$error_switch_harness" <<'C'
#include <stdint.h>

extern int32_t error_switch(uint8_t tag);

int main(void) {
    if (error_switch(0) != 0) return 1;
    if (error_switch(1) != -1) return 2;
    if (error_switch(2) != -2) return 3;
    if (error_switch(255) != -2) return 4;
    return 0;
}
C

zig cc "$error_switch_harness" "$error_switch_object" -o "$error_switch_exe"
"$error_switch_exe"
printf 'ok distribution releasesafe object error_switch_select\n'

globals_fixture="test/distribution/releasesafe_x86_64/inputs/globals_comptime_checked.ll"
globals_object="$tmp_dir/globals_comptime_checked.o"
globals_summary="$tmp_dir/globals_comptime_checked.readelf.txt"
globals_dump="$tmp_dir/globals_comptime_checked.objdump.txt"
globals_harness="$tmp_dir/globals_comptime_checked_harness.c"
globals_exe="$tmp_dir/globals_comptime_checked_harness"

zig build run -- --emit=obj --target="$target" --input-limit=67108864 "$globals_fixture" > "$globals_object"
readelf -W -h -S -s -r "$globals_object" > "$globals_summary"
objdump -dr "$globals_object" > "$globals_dump"

rg -q 'Type:[[:space:]]+REL' "$globals_summary"
rg -q 'Machine:[[:space:]]+Advanced Micro Devices X86-64' "$globals_summary"
rg -q '[[:space:]]comptime_const$' "$globals_summary"
rg -q '[[:space:]]update_global$' "$globals_summary"
rg -q '[[:space:]]read_global$' "$globals_summary"
rg -q '[[:space:]]globals_comptime\.global_counter$' "$globals_summary"
rg -q "R_X86_64_PLT32.*debug.FullPanic\\(\\(function 'defaultPanic'\\)\\)\\.integerOverflow - 4" "$globals_summary"
rg -q "R_X86_64_PC32.*globals_comptime\\.global_counter - 4" "$globals_summary"
rg -q '[[:space:]]jo[[:space:]]' "$globals_dump"

cat > "$globals_harness" <<'C'
#include <stdint.h>

extern int32_t comptime_const(int32_t value);
extern int32_t update_global(int32_t value);
extern int32_t read_global(void);

void panic_overflow_stub(void) __asm__("debug.FullPanic((function 'defaultPanic')).integerOverflow");
void panic_overflow_stub(void) {
    __builtin_trap();
}

int main(void) {
    if (comptime_const(0) != 0) return 1;
    if (comptime_const(7) != 35) return 2;
    if (comptime_const(-3) != -15) return 3;
    if (read_global() != 3) return 4;
    if (update_global(4) != 7) return 5;
    if (read_global() != 7) return 6;
    if (update_global(-2) != 5) return 7;
    if (read_global() != 5) return 8;
    return 0;
}
C

zig cc "$globals_harness" "$globals_object" -o "$globals_exe"
"$globals_exe"
printf 'ok distribution releasesafe object globals_comptime_checked\n'
