#!/usr/bin/env bash
set -euo pipefail

target="${TARGET:-x86_64-unknown-linux-gnu}"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

check_common_object() {
    local summary="$1"
    local symbol="$2"

    rg -q 'Type:[[:space:]]+REL' "$summary"
    rg -q 'Machine:[[:space:]]+Advanced Micro Devices X86-64' "$summary"
    rg -q '\.text' "$summary"
    rg -q '\.symtab' "$summary"
    rg -q "[[:space:]]${symbol}$" "$summary"
    ! rg -q 'llvm\.dbg' "$summary"
}

emit_and_check() {
    local name="$1"
    local symbol="$2"
    local fixture="test/zig/expected/${name}.ll"
    local object="$tmp_dir/${name}.o"
    local summary="$tmp_dir/${name}.readelf.txt"
    local dump="$tmp_dir/${name}.objdump.txt"

    zig build run -- --emit=obj --target="$target" --input-limit=67108864 "$fixture" > "$object"
    readelf -W -h -S -s -r "$object" > "$summary"
    objdump -dr "$object" > "$dump"
    check_common_object "$summary" "$symbol"
}

emit_and_check debug_call_chain.reduced debug_call_chain
rg -q '[[:space:]]debug_callee$' "$tmp_dir/debug_call_chain.reduced.readelf.txt"
rg -q 'R_X86_64_PLT32.*debug_callee' "$tmp_dir/debug_call_chain.reduced.readelf.txt"
rg -q 'add[[:alpha:]]*[[:space:]]+\$0x1,%eax' "$tmp_dir/debug_call_chain.reduced.objdump.txt"
printf 'ok distribution debug object debug_call_chain\n'

emit_and_check debug_declare_intrinsic.reduced debug_declare
rg -q 'There are no relocations in this file' "$tmp_dir/debug_declare_intrinsic.reduced.readelf.txt"
rg -q '[[:space:]]ret' "$tmp_dir/debug_declare_intrinsic.reduced.objdump.txt"
printf 'ok distribution debug object debug_declare_intrinsic\n'

emit_and_check debug_loop_sum.reduced debug_loop_sum
rg -q '[[:space:]]test[[:space:]]+%edi,%edi' "$tmp_dir/debug_loop_sum.reduced.objdump.txt"
rg -q '[[:space:]]js[[:space:]]+' "$tmp_dir/debug_loop_sum.reduced.objdump.txt"
rg -q '[[:space:]]jne[[:space:]]+' "$tmp_dir/debug_loop_sum.reduced.objdump.txt"
printf 'ok distribution debug object debug_loop_sum\n'

emit_and_check debug_metadata.reduced debug_add
rg -q 'add[[:alpha:]]*[[:space:]]+\$0x1,%eax' "$tmp_dir/debug_metadata.reduced.objdump.txt"
printf 'ok distribution debug object debug_metadata\n'

emit_and_check debug_scope_branch.reduced debug_scope_branch
rg -q '[[:space:]]test[[:space:]]+%dil,%dil' "$tmp_dir/debug_scope_branch.reduced.objdump.txt"
rg -q '[[:space:]]jne[[:space:]]+' "$tmp_dir/debug_scope_branch.reduced.objdump.txt"
rg -q 'add[[:alpha:]]*[[:space:]]+\$0x1,%eax' "$tmp_dir/debug_scope_branch.reduced.objdump.txt"
printf 'ok distribution debug object debug_scope_branch\n'

emit_and_check debug_value_intrinsic.reduced debug_value
rg -q '[[:space:]]mov[[:space:]]+%edi,%eax' "$tmp_dir/debug_value_intrinsic.reduced.objdump.txt"
printf 'ok distribution debug object debug_value_intrinsic\n'

emit_and_check debug_pointers_volatile_roundtrip.reduced volatile_roundtrip
rg -q 'There are no relocations in this file' "$tmp_dir/debug_pointers_volatile_roundtrip.reduced.readelf.txt"
rg -q 'mov[[:alpha:]]*[[:space:]]+%esi,\(%rdi\)' "$tmp_dir/debug_pointers_volatile_roundtrip.reduced.objdump.txt"
rg -q 'mov[[:alpha:]]*[[:space:]]+\(%rdi\),%eax' "$tmp_dir/debug_pointers_volatile_roundtrip.reduced.objdump.txt"
printf 'ok distribution debug object debug_pointers_volatile_roundtrip\n'

emit_and_check debug_sizeof_typeof_c_unreachable.reduced c_fopen
rg -q '[[:space:]]c_ftell$' "$tmp_dir/debug_sizeof_typeof_c_unreachable.reduced.readelf.txt"
rg -q '[[:space:]]c_fputs$' "$tmp_dir/debug_sizeof_typeof_c_unreachable.reduced.readelf.txt"
rg -q '[[:space:]]c_printf$' "$tmp_dir/debug_sizeof_typeof_c_unreachable.reduced.readelf.txt"
rg -q 'ud2' "$tmp_dir/debug_sizeof_typeof_c_unreachable.reduced.objdump.txt"
printf 'ok distribution debug object debug_sizeof_typeof_c_unreachable\n'

emit_and_check debug_c_abi_f128_sret.reduced zig_f128_f128_struct
rg -q 'R_X86_64_PLT32.*__eqtf2' "$tmp_dir/debug_c_abi_f128_sret.reduced.readelf.txt"
rg -q 'ud2' "$tmp_dir/debug_c_abi_f128_sret.reduced.objdump.txt"
printf 'ok distribution debug object debug_c_abi_f128_sret\n'

logical_pointer_fixture="test/distribution/debug_x86_64/inputs/logical_pointer_compile_error_o0.ll"
logical_pointer_object="$tmp_dir/logical_pointer_compile_error_o0.o"
logical_pointer_summary="$tmp_dir/logical_pointer_compile_error_o0.readelf.txt"
logical_pointer_dump="$tmp_dir/logical_pointer_compile_error_o0.objdump.txt"

zig build run -- --emit=obj --target="$target" --input-limit=67108864 "$logical_pointer_fixture" > "$logical_pointer_object"
readelf -W -h -S -s -r "$logical_pointer_object" > "$logical_pointer_summary"
objdump -dr "$logical_pointer_object" > "$logical_pointer_dump"

check_common_object "$logical_pointer_summary" ptrIntArithmetic
rg -q '[[:space:]]ptrPtrArithmetic$' "$logical_pointer_summary"
rg -q '[[:space:]]ptrFromInt$' "$logical_pointer_summary"
rg -q '[[:space:]]intFromPtr$' "$logical_pointer_summary"
rg -q '[[:space:]]elemVal$' "$logical_pointer_summary"
rg -q '[[:space:]]elemPtr$' "$logical_pointer_summary"
rg -q '[[:space:]]illegal_operation_on_logical_ptr\.ptrIntArithmetic$' "$logical_pointer_summary"
rg -q '[[:space:]]illegal_operation_on_logical_ptr\.elemPtr$' "$logical_pointer_summary"
rg -q '[[:space:]]ret' "$logical_pointer_dump"
printf 'ok distribution debug object logical_pointer_compile_error_o0\n'

spirv_pointer_fixture="test/distribution/debug_x86_64/inputs/spirv_merge_logical_pointers_o0.ll"
spirv_pointer_object="$tmp_dir/spirv_merge_logical_pointers_o0.o"
spirv_pointer_summary="$tmp_dir/spirv_merge_logical_pointers_o0.readelf.txt"
spirv_pointer_dump="$tmp_dir/spirv_merge_logical_pointers_o0.objdump.txt"

zig build run -- --emit=obj --target="$target" --input-limit=67108864 "$spirv_pointer_fixture" > "$spirv_pointer_object"
readelf -W -h -S -s -r "$spirv_pointer_object" > "$spirv_pointer_summary"
objdump -dr "$spirv_pointer_object" > "$spirv_pointer_dump"

check_common_object "$spirv_pointer_summary" a
rg -q '[[:space:]]spirv_merge_logical_pointers\.a$' "$spirv_pointer_summary"
rg -q '[[:space:]]ret' "$spirv_pointer_dump"
printf 'ok distribution debug object spirv_merge_logical_pointers_o0\n'

inherit_fixture="test/distribution/debug_x86_64/inputs/inherit_want_safety_o0.ll"
inherit_object="$tmp_dir/inherit_want_safety_o0.o"
inherit_summary="$tmp_dir/inherit_want_safety_o0.readelf.txt"
inherit_dump="$tmp_dir/inherit_want_safety_o0.objdump.txt"

zig build run -- --emit=obj --target="$target" --input-limit=67108864 "$inherit_fixture" > "$inherit_object"
readelf -W -h -S -s -r "$inherit_object" > "$inherit_summary"
objdump -dr "$inherit_object" > "$inherit_dump"

check_common_object "$inherit_summary" entry
rg -q '[[:space:]]inherit_want_safety\.entry$' "$inherit_summary"
rg -q 'movabs[[:alpha:]]*[[:space:]]+\$0x4,%rax' "$inherit_dump"
rg -q '[[:space:]]ret' "$inherit_dump"
printf 'ok distribution debug object inherit_want_safety_o0\n'

unchecked_arith_fixture="test/distribution/debug_x86_64/inputs/no_compile_panic_unchecked_arith_o0.ll"
unchecked_arith_object="$tmp_dir/no_compile_panic_unchecked_arith_o0.o"
unchecked_arith_summary="$tmp_dir/no_compile_panic_unchecked_arith_o0.readelf.txt"
unchecked_arith_dump="$tmp_dir/no_compile_panic_unchecked_arith_o0.objdump.txt"

zig build run -- --emit=obj --target="$target" --input-limit=67108864 "$unchecked_arith_fixture" > "$unchecked_arith_object"
readelf -W -h -S -s -r "$unchecked_arith_object" > "$unchecked_arith_summary"
objdump -dr "$unchecked_arith_object" > "$unchecked_arith_dump"

check_common_object "$unchecked_arith_summary" entry
rg -q '[[:space:]]no_compile_panic_for_unchecked_arith\.entry$' "$unchecked_arith_summary"
rg -q 'movabs[[:alpha:]]*[[:space:]]+\$0x0,%rax' "$unchecked_arith_dump"
rg -q '[[:space:]]ret' "$unchecked_arith_dump"
printf 'ok distribution debug object no_compile_panic_unchecked_arith_o0\n'

compile_asm_fixture="test/distribution/debug_x86_64/inputs/compile_asm_panic_o0.ll"
compile_asm_object="$tmp_dir/compile_asm_panic_o0.o"
compile_asm_summary="$tmp_dir/compile_asm_panic_o0.readelf.txt"
compile_asm_dump="$tmp_dir/compile_asm_panic_o0.objdump.txt"

zig build run -- --emit=obj --target="$target" --input-limit=67108864 "$compile_asm_fixture" > "$compile_asm_object"
readelf -W -h -S -s -r "$compile_asm_object" > "$compile_asm_summary"
objdump -dr "$compile_asm_object" > "$compile_asm_dump"

check_common_object "$compile_asm_summary" main
rg -q '[[:space:]]main\.main$' "$compile_asm_summary"
rg -q 'ud2' "$compile_asm_dump"
printf 'ok distribution debug object compile_asm_panic_o0\n'

issue_339_fixture="test/distribution/debug_x86_64/inputs/issue_339_error_success_o0.ll"
issue_339_object="$tmp_dir/issue_339_error_success_o0.o"
issue_339_summary="$tmp_dir/issue_339_error_success_o0.readelf.txt"
issue_339_dump="$tmp_dir/issue_339_error_success_o0.objdump.txt"

zig build run -- --emit=obj --target="$target" --input-limit=67108864 "$issue_339_fixture" > "$issue_339_object"
readelf -W -h -S -s -r "$issue_339_object" > "$issue_339_summary"
objdump -dr "$issue_339_object" > "$issue_339_dump"

check_common_object "$issue_339_summary" foo
rg -q '[[:space:]]test\.foo$' "$issue_339_summary"
rg -q '[[:space:]]ret' "$issue_339_dump"
printf 'ok distribution debug object issue_339_error_success_o0\n'

libfuzzer_fixture="test/distribution/debug_x86_64/inputs/libfuzzer_runner_o0.ll"
libfuzzer_object="$tmp_dir/libfuzzer_runner_o0.o"
libfuzzer_summary="$tmp_dir/libfuzzer_runner_o0.readelf.txt"
libfuzzer_dump="$tmp_dir/libfuzzer_runner_o0.objdump.txt"

zig build run -- --emit=obj --target="$target" --input-limit=67108864 "$libfuzzer_fixture" > "$libfuzzer_object"
readelf -W -h -S -s -r "$libfuzzer_object" > "$libfuzzer_summary"
objdump -dr "$libfuzzer_object" > "$libfuzzer_dump"

check_common_object "$libfuzzer_summary" runner_test_run
rg -q '[[:space:]]runner_broadcast_input$' "$libfuzzer_summary"
rg -q '[[:space:]]runner_futex_wake$' "$libfuzzer_summary"
rg -q '[[:space:]]runner_futex_wait$' "$libfuzzer_summary"
rg -q '[[:space:]]runner_stop_input_poller$' "$libfuzzer_summary"
rg -q '[[:space:]]runner_start_input_poller$' "$libfuzzer_summary"
rg -q '[[:space:]]runner_test_name$' "$libfuzzer_summary"
rg -q '[[:space:]]main\.runner_test_run$' "$libfuzzer_summary"
rg -q 'R_X86_64_PC32.*main\.testOne' "$libfuzzer_summary"
rg -q 'R_X86_64_PLT32.*fuzzer_set_test' "$libfuzzer_summary"
rg -q 'R_X86_64_PLT32.*fuzzer_new_input' "$libfuzzer_summary"
rg -q 'R_X86_64_PLT32.*fuzzer_start_test' "$libfuzzer_summary"
rg -q '[[:space:]]ret' "$libfuzzer_dump"
printf 'ok distribution debug object libfuzzer_runner_o0\n'

load_dynamic_add_fixture="test/distribution/debug_x86_64/inputs/load_dynamic_library_add_o0.ll"
load_dynamic_add_object="$tmp_dir/load_dynamic_library_add_o0.o"
load_dynamic_add_summary="$tmp_dir/load_dynamic_library_add_o0.readelf.txt"
load_dynamic_add_dump="$tmp_dir/load_dynamic_library_add_o0.objdump.txt"

zig build run -- --emit=obj --target="$target" --input-limit=67108864 "$load_dynamic_add_fixture" > "$load_dynamic_add_object"
readelf -W -h -S -s -r "$load_dynamic_add_object" > "$load_dynamic_add_summary"
objdump -dr "$load_dynamic_add_object" > "$load_dynamic_add_dump"

check_common_object "$load_dynamic_add_summary" add
rg -q '[[:space:]]add\.add$' "$load_dynamic_add_summary"
rg -q "R_X86_64_PLT32.*debug\\.FullPanic\\(\\(function 'defaultPanic'\\)\\)\\.integerOverflow" "$load_dynamic_add_summary"
rg -q '[[:space:]]jo[[:space:]]+' "$load_dynamic_add_dump"
rg -q '[[:space:]]ret' "$load_dynamic_add_dump"
printf 'ok distribution debug object load_dynamic_library_add_o0\n'

mix_c_files_fixture="test/distribution/debug_x86_64/inputs/mix_c_files_main_o0.ll"
mix_c_files_object="$tmp_dir/mix_c_files_main_o0.o"
mix_c_files_summary="$tmp_dir/mix_c_files_main_o0.readelf.txt"
mix_c_files_dump="$tmp_dir/mix_c_files_main_o0.objdump.txt"

zig build run -- --emit=obj --target="$target" --input-limit=67108864 "$mix_c_files_fixture" > "$mix_c_files_object"
readelf -W -h -S -s -r "$mix_c_files_object" > "$mix_c_files_summary"
objdump -dr "$mix_c_files_object" > "$mix_c_files_dump"

check_common_object "$mix_c_files_summary" add_zig
rg -q '[[:space:]]add_may_panic$' "$mix_c_files_summary"
rg -q '[[:space:]]zig_k$' "$mix_c_files_summary"
rg -q 'R_X86_64_PC32.*main\.zig_k' "$mix_c_files_summary"
rg -q 'R_X86_64_TPOFF32.*C_k' "$mix_c_files_summary"
rg -q "R_X86_64_PLT32.*debug\\.FullPanic\\(\\(function 'defaultPanic'\\)\\)\\.integerOverflow" "$mix_c_files_summary"
rg -q 'R_X86_64_PLT32.*debug\.defaultPanic' "$mix_c_files_summary"
rg -q '[[:space:]]jo[[:space:]]+' "$mix_c_files_dump"
rg -q '[[:space:]]js[[:space:]]+' "$mix_c_files_dump"
rg -q 'ud2' "$mix_c_files_dump"
printf 'ok distribution debug object mix_c_files_main_o0\n'

shared_library_fixture="test/distribution/debug_x86_64/inputs/shared_library_mathtest_add_o0.ll"
shared_library_object="$tmp_dir/shared_library_mathtest_add_o0.o"
shared_library_summary="$tmp_dir/shared_library_mathtest_add_o0.readelf.txt"
shared_library_dump="$tmp_dir/shared_library_mathtest_add_o0.objdump.txt"

zig build run -- --emit=obj --target="$target" --input-limit=67108864 "$shared_library_fixture" > "$shared_library_object"
readelf -W -h -S -s -r "$shared_library_object" > "$shared_library_summary"
objdump -dr "$shared_library_object" > "$shared_library_dump"

check_common_object "$shared_library_summary" add
rg -q '[[:space:]]mathtest\.add$' "$shared_library_summary"
rg -q "R_X86_64_PLT32.*debug\\.FullPanic\\(\\(function 'defaultPanic'\\)\\)\\.integerOverflow" "$shared_library_summary"
rg -q '[[:space:]]jo[[:space:]]+' "$shared_library_dump"
rg -q '[[:space:]]ret' "$shared_library_dump"
printf 'ok distribution debug object shared_library_mathtest_add_o0\n'

printf 'ok distribution debug reduced object target=%s\n' "$target"
