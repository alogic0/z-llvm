#!/usr/bin/env bash
set -euo pipefail

target="${TARGET:-x86_64-unknown-linux-gnu}"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

fixture="test/distribution/releasesmall_x86_64/inputs/export_keyword_vram_store.ll"
object="$tmp_dir/export_keyword_vram_store.o"
summary="$tmp_dir/export_keyword_vram_store.readelf.txt"
dump="$tmp_dir/export_keyword_vram_store.objdump.txt"

zig build run -- --emit=obj --target="$target" --input-limit=67108864 "$fixture" > "$object"
readelf -W -h -S -s -r "$object" > "$summary"
objdump -dr "$object" > "$dump"

rg -q 'Type:[[:space:]]+REL' "$summary"
rg -q 'Machine:[[:space:]]+Advanced Micro Devices X86-64' "$summary"
rg -q '[[:space:]]testPackedStuff$' "$summary"
rg -q '[[:space:]]writeToVRam$' "$summary"
rg -q 'movb[[:space:]]+\$0x58,0x20000000' "$dump"

printf 'ok distribution releasesmall object export_keyword_vram_store\n'

stubs_fixture="test/distribution/releasesmall_x86_64/inputs/sizeof_typeof_unreachable_stubs.ll"
stubs_object="$tmp_dir/sizeof_typeof_unreachable_stubs.o"
stubs_summary="$tmp_dir/sizeof_typeof_unreachable_stubs.readelf.txt"
stubs_dump="$tmp_dir/sizeof_typeof_unreachable_stubs.objdump.txt"

zig build run -- --emit=obj --target="$target" --input-limit=67108864 "$stubs_fixture" > "$stubs_object"
readelf -W -h -S -s -r "$stubs_object" > "$stubs_summary"
objdump -dr "$stubs_object" > "$stubs_dump"

rg -q 'Type:[[:space:]]+REL' "$stubs_summary"
rg -q 'Machine:[[:space:]]+Advanced Micro Devices X86-64' "$stubs_summary"
rg -q '[[:space:]]c_fopen$' "$stubs_summary"
rg -q '[[:space:]]c_ftell$' "$stubs_summary"
rg -q '[[:space:]]c_fputs$' "$stubs_summary"
rg -q '[[:space:]]c_printf$' "$stubs_summary"
rg -q '[[:space:]]ud2' "$stubs_dump"

printf 'ok distribution releasesmall object sizeof_typeof_unreachable_stubs\n'

f128_fixture="test/distribution/releasesmall_x86_64/inputs/c_abi_main_f128_sret.ll"
f128_object="$tmp_dir/c_abi_main_f128_sret.o"
f128_summary="$tmp_dir/c_abi_main_f128_sret.readelf.txt"
f128_dump="$tmp_dir/c_abi_main_f128_sret.objdump.txt"

zig build run -- --emit=obj --target="$target" --input-limit=67108864 "$f128_fixture" > "$f128_object"
readelf -W -h -S -s -r "$f128_object" > "$f128_summary"
objdump -dr "$f128_object" > "$f128_dump"

rg -q 'Type:[[:space:]]+REL' "$f128_summary"
rg -q 'Machine:[[:space:]]+Advanced Micro Devices X86-64' "$f128_summary"
rg -q '[[:space:]]zig_f128_f128_struct$' "$f128_summary"
rg -q '[[:space:]]zig_f128_struct$' "$f128_summary"
rg -q '[[:space:]]zig_f128$' "$f128_summary"
rg -q '[[:space:]]zig_assert_PD$' "$f128_summary"
rg -q '[[:space:]]zig_ret_PD$' "$f128_summary"
rg -q '[[:space:]]zig_ret_CFF$' "$f128_summary"
rg -q '[[:space:]]zig_assert_CFF$' "$f128_summary"
rg -q '[[:space:]]zig_ret_DC$' "$f128_summary"
rg -q '[[:space:]]zig_assert_DC$' "$f128_summary"
rg -q '[[:space:]]zig_ret_split_struct_mixed$' "$f128_summary"
rg -q '[[:space:]]zig_ret_med_struct_mixed$' "$f128_summary"
rg -q '[[:space:]]__zllvm_f128_cmp0$' "$f128_summary"
rg -q '[[:space:]]__zllvm_f128_ret1$' "$f128_summary"
rg -q '[[:space:]]__zllvm_f128_struct_ret0$' "$f128_summary"
rg -q '[[:space:]]__zllvm_f128_scalar_ret0$' "$f128_summary"
rg -q 'R_X86_64_PLT32.*__eqtf2' "$f128_summary"
rg -q 'R_X86_64_PC32.*__zllvm_f128_cmp0' "$f128_summary"
rg -q 'R_X86_64_PC32.*__zllvm_f128_ret1' "$f128_summary"
rg -q 'R_X86_64_PC32.*__zllvm_f128_struct_ret0' "$f128_summary"
rg -q 'R_X86_64_PC32.*__zllvm_f128_scalar_ret0' "$f128_summary"
rg -q 'R_X86_64_PLT32.*__eqtf2' "$f128_dump"
rg -q 'movaps[[:space:]]+.*%xmm0' "$f128_dump"
rg -q 'ucomisd[[:space:]]+%xmm1,%xmm0' "$f128_dump"
rg -q 'movq[[:space:]]+%rax,%xmm0' "$f128_dump"
rg -q 'movabs[[:space:]]+\$0x3f60000000000027,%rax' "$f128_dump"
rg -q 'movabs[[:space:]]+\$0xbfd0000000000000,%rax' "$f128_dump"
rg -q 'movabs[[:space:]]+\$0xf,%rax' "$f128_dump"
rg -q 'movabs[[:space:]]+\$0x4d2,%rax' "$f128_dump"
rg -q 'movabs[[:space:]]+\$0x44a7200000000064,%rdx' "$f128_dump"
rg -q 'movabs[[:space:]]+\$0x42c80000000004d2,%rax' "$f128_dump"
rg -q 'movabs[[:space:]]+\$0x44a72000,%rdx' "$f128_dump"
rg -q 'cmp[[:alpha:]]*[[:space:]]+\$0xf,%dil' "$f128_dump"
rg -q 'ucomiss[[:space:]]+%xmm1,%xmm0' "$f128_dump"
rg -q 'jp[[:space:]]+' "$f128_dump"
rg -q '[[:space:]]ud2' "$f128_dump"

printf 'ok distribution releasesmall object c_abi_main_f128_sret\n'
