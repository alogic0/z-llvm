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

zig cc -target "$cc_target" "$harness" "$object" -o "$exe"
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

zig cc -target "$cc_target" "$atomics_harness" "$atomics_object" -o "$atomics_exe"
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

zig cc -target "$cc_target" "$control_flow_harness" "$control_flow_object" -o "$control_flow_exe"
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

zig cc -target "$cc_target" "$error_switch_harness" "$error_switch_object" -o "$error_switch_exe"
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

zig cc -target "$cc_target" "$globals_harness" "$globals_object" -o "$globals_exe"
"$globals_exe"
printf 'ok distribution releasesafe object globals_comptime_checked\n'

pointers_fixture="test/distribution/releasesafe_x86_64/inputs/pointers_memory_checked.ll"
pointers_object="$tmp_dir/pointers_memory_checked.o"
pointers_summary="$tmp_dir/pointers_memory_checked.readelf.txt"
pointers_dump="$tmp_dir/pointers_memory_checked.objdump.txt"
pointers_harness="$tmp_dir/pointers_memory_checked_harness.c"
pointers_exe="$tmp_dir/pointers_memory_checked_harness"

zig build run -- --emit=obj --target="$target" --input-limit=67108864 "$pointers_fixture" > "$pointers_object"
readelf -W -h -S -s -r "$pointers_object" > "$pointers_summary"
objdump -dr "$pointers_object" > "$pointers_dump"

rg -q 'Type:[[:space:]]+REL' "$pointers_summary"
rg -q 'Machine:[[:space:]]+Advanced Micro Devices X86-64' "$pointers_summary"
rg -q '[[:space:]]load_store$' "$pointers_summary"
rg -q "R_X86_64_PLT32.*debug.FullPanic\\(\\(function 'defaultPanic'\\)\\)\\.integerOverflow - 4" "$pointers_summary"
rg -q '[[:space:]]jo[[:space:]]' "$pointers_dump"

cat > "$pointers_harness" <<'C'
#include <stdint.h>

extern int32_t load_store(const int32_t *input, int32_t *output);

void panic_overflow_stub(void) __asm__("debug.FullPanic((function 'defaultPanic')).integerOverflow");
void panic_overflow_stub(void) {
    __builtin_trap();
}

int main(void) {
    int32_t input = 41;
    int32_t output = 0;
    if (load_store(&input, &output) != 42) return 1;
    if (output != 42) return 2;
    input = -3;
    if (load_store(&input, &output) != -2) return 3;
    if (output != -2) return 4;
    return 0;
}
C

zig cc -target "$cc_target" "$pointers_harness" "$pointers_object" -o "$pointers_exe"
"$pointers_exe"
printf 'ok distribution releasesafe object pointers_memory_checked\n'

switch_fixture="test/distribution/releasesafe_x86_64/inputs/switch_control_branch_mix_checked.ll"
switch_object="$tmp_dir/switch_control_branch_mix_checked.o"
switch_summary="$tmp_dir/switch_control_branch_mix_checked.readelf.txt"
switch_dump="$tmp_dir/switch_control_branch_mix_checked.objdump.txt"
switch_harness="$tmp_dir/switch_control_branch_mix_checked_harness.c"
switch_exe="$tmp_dir/switch_control_branch_mix_checked_harness"

zig build run -- --emit=obj --target="$target" --input-limit=67108864 "$switch_fixture" > "$switch_object"
readelf -W -h -S -s -r "$switch_object" > "$switch_summary"
objdump -dr "$switch_object" > "$switch_dump"

rg -q 'Type:[[:space:]]+REL' "$switch_summary"
rg -q 'Machine:[[:space:]]+Advanced Micro Devices X86-64' "$switch_summary"
rg -q '[[:space:]]branch_mix$' "$switch_summary"
rg -q "R_X86_64_PLT32.*debug.FullPanic\\(\\(function 'defaultPanic'\\)\\)\\.integerOverflow - 4" "$switch_summary"
rg -q '[[:space:]]jo[[:space:]]' "$switch_dump"
rg -q '[[:space:]]je[[:space:]]' "$switch_dump"

cat > "$switch_harness" <<'C'
#include <stdbool.h>
#include <stdint.h>

extern int32_t branch_mix(int32_t base, int32_t delta, bool add);

void panic_overflow_stub(void) __asm__("debug.FullPanic((function 'defaultPanic')).integerOverflow");
void panic_overflow_stub(void) {
    __builtin_trap();
}

int main(void) {
    if (branch_mix(10, 4, true) != 14) return 1;
    if (branch_mix(10, 4, false) != 6) return 2;
    if (branch_mix(-7, 3, true) != -4) return 3;
    if (branch_mix(-7, 3, false) != -10) return 4;
    return 0;
}
C

zig cc -target "$cc_target" "$switch_harness" "$switch_object" -o "$switch_exe"
"$switch_exe"
printf 'ok distribution releasesafe object switch_control_branch_mix_checked\n'

tiny_fixture="test/distribution/releasesafe_x86_64/inputs/tiny_scalar_checked_add.ll"
tiny_object="$tmp_dir/tiny_scalar_checked_add.o"
tiny_summary="$tmp_dir/tiny_scalar_checked_add.readelf.txt"
tiny_dump="$tmp_dir/tiny_scalar_checked_add.objdump.txt"
tiny_harness="$tmp_dir/tiny_scalar_checked_add_harness.c"
tiny_exe="$tmp_dir/tiny_scalar_checked_add_harness"

zig build run -- --emit=obj --target="$target" --input-limit=67108864 "$tiny_fixture" > "$tiny_object"
readelf -W -h -S -s -r "$tiny_object" > "$tiny_summary"
objdump -dr "$tiny_object" > "$tiny_dump"

rg -q 'Type:[[:space:]]+REL' "$tiny_summary"
rg -q 'Machine:[[:space:]]+Advanced Micro Devices X86-64' "$tiny_summary"
rg -q '[[:space:]]sideEffectFree$' "$tiny_summary"
rg -q '[[:space:]]add$' "$tiny_summary"
rg -q "R_X86_64_PLT32.*debug.FullPanic\\(\\(function 'defaultPanic'\\)\\)\\.integerOverflow - 4" "$tiny_summary"
rg -q '[[:space:]]jo[[:space:]]' "$tiny_dump"

cat > "$tiny_harness" <<'C'
#include <stdint.h>

extern void sideEffectFree(void);
extern int32_t add(int32_t lhs, int32_t rhs);

void panic_overflow_stub(void) __asm__("debug.FullPanic((function 'defaultPanic')).integerOverflow");
void panic_overflow_stub(void) {
    __builtin_trap();
}

int main(void) {
    sideEffectFree();
    if (add(1, 2) != 3) return 1;
    if (add(-7, 2) != -5) return 2;
    if (add(1000, -250) != 750) return 3;
    return 0;
}
C

zig cc -target "$cc_target" "$tiny_harness" "$tiny_object" -o "$tiny_exe"
"$tiny_exe"
printf 'ok distribution releasesafe object tiny_scalar_checked_add\n'

tls_fixture="test/distribution/releasesafe_x86_64/inputs/tls_concurrency_checked.ll"
tls_object="$tmp_dir/tls_concurrency_checked.o"
tls_summary="$tmp_dir/tls_concurrency_checked.readelf.txt"
tls_dump="$tmp_dir/tls_concurrency_checked.objdump.txt"
tls_harness="$tmp_dir/tls_concurrency_checked_harness.c"
tls_exe="$tmp_dir/tls_concurrency_checked_harness"

zig build run -- --emit=obj --target="$target" --input-limit=67108864 "$tls_fixture" > "$tls_object"
readelf -W -h -S -s -r "$tls_object" > "$tls_summary"
objdump -dr "$tls_object" > "$tls_dump"

rg -q 'Type:[[:space:]]+REL' "$tls_summary"
rg -q 'Machine:[[:space:]]+Advanced Micro Devices X86-64' "$tls_summary"
rg -q '[[:space:]]bump_tls$' "$tls_summary"
rg -q '[[:space:]]read_tls$' "$tls_summary"
rg -q '\.tdata' "$tls_summary"
rg -q 'TLS[[:space:]]+GLOBAL.*tls_concurrency\.tls_counter' "$tls_summary"
rg -q 'R_X86_64_TPOFF32.*tls_concurrency\.tls_counter' "$tls_summary"
rg -q "R_X86_64_PLT32.*debug.FullPanic\\(\\(function 'defaultPanic'\\)\\)\\.integerOverflow - 4" "$tls_summary"
rg -q '[[:space:]]jo[[:space:]]' "$tls_dump"

cat > "$tls_harness" <<'C'
#include <stdint.h>

extern int32_t bump_tls(int32_t delta);
extern int32_t read_tls(void);

void panic_overflow_stub(void) __asm__("debug.FullPanic((function 'defaultPanic')).integerOverflow");
void panic_overflow_stub(void) {
    __builtin_trap();
}

int main(void) {
    if (read_tls() != 1) return 1;
    if (bump_tls(4) != 5) return 2;
    if (read_tls() != 5) return 3;
    if (bump_tls(-2) != 3) return 4;
    if (read_tls() != 3) return 5;
    return 0;
}
C

zig cc -target "$cc_target" "$tls_harness" "$tls_object" -o "$tls_exe"
"$tls_exe"
printf 'ok distribution releasesafe object tls_concurrency_checked\n'
