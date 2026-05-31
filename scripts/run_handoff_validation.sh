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

run_optimized_codegen_case() {
  local id="$1"
  local passes="$2"
  local input="$3"
  local expected_ir="$4"
  local expected_asm="$5"
  local expected_objdump="$6"
  local optimized_ir="$tmp_dir/$id.optimized.ll"
  local optimized_norm="$tmp_dir/$id.optimized.norm.ll"
  local expected_norm="$tmp_dir/$id.expected.norm.ll"
  local llvm_ir="$tmp_dir/$id.llvm.ll"
  local llvm_norm="$tmp_dir/$id.llvm.norm.ll"
  local local_asm="$tmp_dir/$id.s"
  local local_obj="$tmp_dir/$id.local.o"
  local local_objdump="$tmp_dir/$id.local.objdump.txt"
  local llvm_obj="$tmp_dir/$id.llvm.o"
  local llvm_objdump="$tmp_dir/$id.llvm.objdump.txt"

  zig build run -- --passes="$passes" "$input" > "$optimized_ir"
  zig run src/normalize_cli.zig -- "$optimized_ir" > "$optimized_norm"
  zig run src/normalize_cli.zig -- "$expected_ir" > "$expected_norm"
  diff -u "$expected_norm" "$optimized_norm"

  opt-22 -S -passes="$passes" "$input" -o "$llvm_ir"
  zig run src/normalize_cli.zig -- "$llvm_ir" > "$llvm_norm"
  diff -u "$llvm_norm" "$optimized_norm"

  zig build run -- --emit=asm --target=x86_64-unknown-linux-gnu "$optimized_ir" > "$local_asm"
  diff -u "$expected_asm" "$local_asm"

  zig build run -- --emit=obj --target=x86_64-unknown-linux-gnu "$optimized_ir" > "$local_obj"
  objdump -dr "$local_obj" | sed -n '/Disassembly of section .text:/,$p' > "$local_objdump"
  diff -u "$expected_objdump" "$local_objdump"

  llc-22 -filetype=obj "$llvm_ir" -o "$llvm_obj"
  objdump -dr "$llvm_obj" | sed -n '/Disassembly of section .text:/,$p' > "$llvm_objdump"
  diff -u "$llvm_objdump" "$local_objdump"

  printf 'ok handoff optimized-codegen %s [%s]\n' "$id" "$passes"
}

run_optimized_codegen_case \
  scalar_add_zero \
  instcombine,dce \
  test/handoff/inputs/scalar_add_zero.ll \
  test/handoff/expected/ir/scalar_add_zero.ll \
  test/handoff/expected/asm/scalar_add_zero.s \
  test/handoff/expected/objdump/scalar_add_zero.txt

run_empty_module_object_case() {
  local id="$1"
  local input="$2"
  local local_asm="$tmp_dir/$id.s"
  local local_obj="$tmp_dir/$id.o"
  local readelf_summary="$tmp_dir/$id.readelf.txt"

  zig build run -- --emit=asm --target=x86_64-unknown-linux-gnu "$input" > "$local_asm"
  test ! -s "$local_asm"

  zig build run -- --emit=obj --target=x86_64-unknown-linux-gnu "$input" > "$local_obj"
  readelf -h -S -s "$local_obj" > "$readelf_summary"
  rg -q 'Type:[[:space:]]+REL' "$readelf_summary"
  rg -q 'Machine:[[:space:]]+Advanced Micro Devices X86-64' "$readelf_summary"
  rg -q '\.text' "$readelf_summary"
  rg -q '\.symtab' "$readelf_summary"

  printf 'ok handoff empty-module object %s\n' "$id"
}

run_empty_module_object_case \
  releasefast_empty_module \
  test/handoff/inputs/releasefast_empty_module.ll

run_debug_handoff_case() {
  local id="$1"
  local input="$2"
  local local_asm="$tmp_dir/$id.s"
  local local_obj="$tmp_dir/$id.o"
  local readelf_summary="$tmp_dir/$id.readelf.txt"

  zig build run -- --emit=asm --target=x86_64-unknown-linux-gnu --input-limit=67108864 "$input" > "$local_asm"
  rg -q '^mathtest\.add:$' "$local_asm"
  rg -q '[[:space:]]add[[:alpha:]]*[[:space:]]+%esi,[[:space:]]*%eax' "$local_asm"
  rg -q '[[:space:]]jo[[:space:]]+' "$local_asm"
  rg -F -q "callq debug.FullPanic((function 'defaultPanic')).integerOverflow" "$local_asm"
  rg -q '[[:space:]]retq' "$local_asm"

  zig build run -- --emit=obj --target=x86_64-unknown-linux-gnu --input-limit=67108864 "$input" > "$local_obj"
  readelf -W -h -S -s -r "$local_obj" > "$readelf_summary"
  rg -q 'Type:[[:space:]]+REL' "$readelf_summary"
  rg -q 'Machine:[[:space:]]+Advanced Micro Devices X86-64' "$readelf_summary"
  rg -q '[[:space:]]mathtest\.add$' "$readelf_summary"
  rg -q "R_X86_64_PLT32.*debug\\.FullPanic\\(\\(function 'defaultPanic'\\)\\)\\.integerOverflow" "$readelf_summary"

  printf 'ok handoff debug %s\n' "$id"
}

run_debug_handoff_case \
  debug_o0_mathtest_checked_add \
  test/distribution/debug_x86_64/inputs/shared_library_mathtest_add_o0.ll

run_asm_case() {
  local id="$1"
  local input="test/codegen/inputs/$id.ll"
  local expected="test/codegen/expected/asm/$id.s"
  local actual="$tmp_dir/$id.s"

  zig build run -- --emit=asm --target=x86_64-unknown-linux-gnu "$input" > "$actual"
  diff -u "$expected" "$actual"
  printf 'ok handoff asm %s\n' "$id"
}

run_asm_case return_constant
run_asm_case call_one_arg
run_asm_case stack_slot
run_asm_case call_stack_slot

bash scripts/compare_codegen_asm.sh
printf 'ok handoff codegen asm smoke\n'

bash scripts/compare_codegen_objdump.sh
printf 'ok handoff codegen objdump smoke\n'

bash scripts/compare_codegen_readelf.sh
printf 'ok handoff codegen readelf smoke\n'
