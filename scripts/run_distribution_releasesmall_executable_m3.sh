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

inherit_fixture="test/distribution/releasesmall_x86_64/inputs/inherit_want_safety_i64_return.ll"
inherit_object="$tmp_dir/inherit_want_safety_i64_return.o"
inherit_harness="$tmp_dir/inherit_want_safety_i64_return_harness.c"
inherit_exe="$tmp_dir/inherit_want_safety_i64_return_harness"

zig build run -- --emit=obj --target="$target" --input-limit=67108864 "$inherit_fixture" > "$inherit_object"

cat > "$inherit_harness" <<'C'
#include <stdint.h>

extern int64_t entry(void);

int main(void) {
    return entry() == 4 ? 0 : 1;
}
C

zig cc -target "$cc_target" "$inherit_harness" "$inherit_object" -o "$inherit_exe"
"$inherit_exe"
printf 'ok distribution releasesmall executable inherit_want_safety_i64_return\n'

unchecked_fixture="test/distribution/releasesmall_x86_64/inputs/no_compile_panic_for_unchecked_arith_umul_fix_sat_i64.ll"
unchecked_object="$tmp_dir/no_compile_panic_for_unchecked_arith_umul_fix_sat_i64.o"
unchecked_harness="$tmp_dir/no_compile_panic_for_unchecked_arith_umul_fix_sat_i64_harness.c"
unchecked_exe="$tmp_dir/no_compile_panic_for_unchecked_arith_umul_fix_sat_i64_harness"

zig build run -- --emit=obj --target="$target" --input-limit=67108864 "$unchecked_fixture" > "$unchecked_object"

cat > "$unchecked_harness" <<'C'
#include <stdint.h>

extern int64_t entry(void);

int main(void) {
    return entry() == 0 ? 0 : 1;
}
C

zig cc -target "$cc_target" "$unchecked_harness" "$unchecked_object" -o "$unchecked_exe"
"$unchecked_exe"
printf 'ok distribution releasesmall executable no_compile_panic_for_unchecked_arith_umul_fix_sat_i64\n'

exports_fixture="test/distribution/releasesmall_x86_64/inputs/standalone_extern_exports_hidden_access.ll"
exports_object="$tmp_dir/standalone_extern_exports_hidden_access.o"
exports_harness="$tmp_dir/standalone_extern_exports_hidden_access_harness.c"
exports_exe="$tmp_dir/standalone_extern_exports_hidden_access_harness"

zig build run -- --emit=obj --target="$target" --input-limit=67108864 "$exports_fixture" > "$exports_object"

cat > "$exports_harness" <<'C'
#include <stdint.h>

extern int32_t getHidden(void);
extern void updateHidden(int32_t value);

int main(void) {
    if (getHidden() != 0) return 1;
    updateHidden(42);
    if (getHidden() != 42) return 2;
    updateHidden(-7);
    if (getHidden() != -7) return 3;
    return 0;
}
C

zig cc -target "$cc_target" "$exports_harness" "$exports_object" -o "$exports_exe"
"$exports_exe"
printf 'ok distribution releasesmall executable standalone_extern_exports_hidden_access\n'

add_zig_fixture="test/distribution/releasesmall_x86_64/inputs/standalone_mix_c_files_add_zig.ll"
add_zig_object="$tmp_dir/standalone_mix_c_files_add_zig.o"
add_zig_harness="$tmp_dir/standalone_mix_c_files_add_zig_harness.c"
add_zig_exe="$tmp_dir/standalone_mix_c_files_add_zig_harness"

zig build run -- --emit=obj --target="$target" --input-limit=67108864 "$add_zig_fixture" > "$add_zig_object"

cat > "$add_zig_harness" <<'C'
#include <stdint.h>

extern int32_t add_zig(int32_t value);
__thread int32_t C_k = 7;

int main(void) {
    if (add_zig(10) != 18) return 1;
    C_k = -3;
    if (add_zig(10) != 8) return 2;
    return 0;
}
C

zig cc -target "$cc_target" "$add_zig_harness" "$add_zig_object" -o "$add_zig_exe"
"$add_zig_exe"
printf 'ok distribution releasesmall executable standalone_mix_c_files_add_zig\n'

add_may_panic_fixture="test/distribution/releasesmall_x86_64/inputs/standalone_mix_c_files_add_may_panic.ll"
add_may_panic_object="$tmp_dir/standalone_mix_c_files_add_may_panic.o"
add_may_panic_harness="$tmp_dir/standalone_mix_c_files_add_may_panic_harness.c"
add_may_panic_exe="$tmp_dir/standalone_mix_c_files_add_may_panic_harness"

zig build run -- --emit=obj --target="$target" --input-limit=67108864 "$add_may_panic_fixture" > "$add_may_panic_object"

cat > "$add_may_panic_harness" <<'C'
#include <stdint.h>

extern int32_t add_may_panic(int32_t value);

void panic_stub(const char *message, int64_t len) __asm__("debug.defaultPanic");
void panic_stub(const char *message, int64_t len) {
    (void)message;
    (void)len;
    __builtin_trap();
}

int main(void) {
    if (add_may_panic(0) != 1) return 1;
    if (add_may_panic(41) != 42) return 2;
    return 0;
}
C

zig cc -target "$cc_target" "$add_may_panic_harness" "$add_may_panic_object" -o "$add_may_panic_exe"
"$add_may_panic_exe"
printf 'ok distribution releasesmall executable standalone_mix_c_files_add_may_panic\n'

futex_fixture="test/distribution/releasesmall_x86_64/inputs/standalone_libfuzzer_runner_futex_wait.ll"
futex_object="$tmp_dir/standalone_libfuzzer_runner_futex_wait.o"
futex_harness="$tmp_dir/standalone_libfuzzer_runner_futex_wait_harness.c"
futex_exe="$tmp_dir/standalone_libfuzzer_runner_futex_wait_harness"

zig build run -- --emit=obj --target="$target" --input-limit=67108864 "$futex_fixture" > "$futex_object"

cat > "$futex_harness" <<'C'
#include <stdbool.h>
#include <stdint.h>

extern bool runner_futex_wait(const int32_t *address, int32_t expected);

int main(void) {
    int32_t value = 7;
    return runner_futex_wait(&value, 7) ? 1 : 0;
}
C

zig cc -target "$cc_target" "$futex_harness" "$futex_object" -o "$futex_exe"
"$futex_exe"
printf 'ok distribution releasesmall executable standalone_libfuzzer_runner_futex_wait\n'

test_name_fixture="test/distribution/releasesmall_x86_64/inputs/standalone_libfuzzer_runner_test_name.ll"
test_name_object="$tmp_dir/standalone_libfuzzer_runner_test_name.o"
test_name_harness="$tmp_dir/standalone_libfuzzer_runner_test_name_harness.c"
test_name_exe="$tmp_dir/standalone_libfuzzer_runner_test_name_harness"

zig build run -- --emit=obj --target="$target" --input-limit=67108864 "$test_name_fixture" > "$test_name_object"

cat > "$test_name_harness" <<'C'
#include <stdint.h>
#include <string.h>

struct Slice {
    uintptr_t ptr;
    uint64_t len;
};

extern struct Slice runner_test_name(int32_t index);

int main(void) {
    struct Slice name = runner_test_name(0);
    if (name.len != 4) return 1;
    if (memcmp((const void *)name.ptr, "test", 4) != 0) return 2;
    return 0;
}
C

zig cc -target "$cc_target" "$test_name_harness" "$test_name_object" -o "$test_name_exe"
"$test_name_exe"
printf 'ok distribution releasesmall executable standalone_libfuzzer_runner_test_name\n'
