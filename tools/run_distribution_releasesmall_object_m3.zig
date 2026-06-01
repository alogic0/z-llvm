const std = @import("std");
const common = @import("tool_common.zig");

const Case = struct {
    id: []const u8,
    fixture: []const u8,
    summary_patterns: []const []const u8 = &.{},
    dump_patterns: []const []const u8 = &.{},
    embedded_checks: ?[]const u8 = null,
};

const f128_checks =
    \\rg -q 'Type:[[:space:]]+REL' "$f128_summary"
    \\rg -q 'Machine:[[:space:]]+Advanced Micro Devices X86-64' "$f128_summary"
    \\rg -q '[[:space:]]zig_f128_f128_struct$' "$f128_summary"
    \\rg -q '[[:space:]]zig_f128_struct$' "$f128_summary"
    \\rg -q '[[:space:]]zig_f128$' "$f128_summary"
    \\rg -q '[[:space:]]zig_assert_PD$' "$f128_summary"
    \\rg -q '[[:space:]]zig_ret_PD$' "$f128_summary"
    \\rg -q '[[:space:]]zig_ret_CFF$' "$f128_summary"
    \\rg -q '[[:space:]]zig_assert_CFF$' "$f128_summary"
    \\rg -q '[[:space:]]zig_ret_DC$' "$f128_summary"
    \\rg -q '[[:space:]]zig_assert_DC$' "$f128_summary"
    \\rg -q '[[:space:]]zig_ret_split_struct_mixed$' "$f128_summary"
    \\rg -q '[[:space:]]zig_ret_med_struct_mixed$' "$f128_summary"
    \\rg -q '[[:space:]]zig_ret_med_struct_ints$' "$f128_summary"
    \\rg -q '[[:space:]]zig_ret_i64$' "$f128_summary"
    \\rg -q '[[:space:]]zig_ret_i16$' "$f128_summary"
    \\rg -q '[[:space:]]zig_ret_i8$' "$f128_summary"
    \\rg -q '[[:space:]]zig_ret_u16$' "$f128_summary"
    \\rg -q '[[:space:]]zig_ret_u8$' "$f128_summary"
    \\rg -q '[[:space:]]zig_ret_bool$' "$f128_summary"
    \\rg -q '[[:space:]]zig_multiple_struct_floats$' "$f128_summary"
    \\rg -q '[[:space:]]zig_multiple_struct_ints$' "$f128_summary"
    \\rg -q '[[:space:]]zig_big_struct_both$' "$f128_summary"
    \\rg -q '[[:space:]]zig_split_struct_mixed$' "$f128_summary"
    \\rg -q '[[:space:]]zig_split_struct_ints$' "$f128_summary"
    \\rg -q '[[:space:]]zig_big_packed_struct$' "$f128_summary"
    \\rg -q '[[:space:]]zig_small_packed_struct$' "$f128_summary"
    \\rg -q '[[:space:]]zig_med_struct_ints$' "$f128_summary"
    \\rg -q '[[:space:]]zig_small_struct_ints$' "$f128_summary"
    \\rg -q '[[:space:]]zig_med_struct_mixed$' "$f128_summary"
    \\rg -q '[[:space:]]zig_big_union$' "$f128_summary"
    \\rg -q '[[:space:]]zig_big_struct$' "$f128_summary"
    \\rg -q '[[:space:]]zig_struct_i32_i32$' "$f128_summary"
    \\rg -q '[[:space:]]zig_struct_f32_f32f32$' "$f128_summary"
    \\rg -q '[[:space:]]zig_struct_f32f32_f32$' "$f128_summary"
    \\rg -q '[[:space:]]zig_ret_struct_f32_f32f32$' "$f128_summary"
    \\rg -q '[[:space:]]zig_ret_struct_f32f32_f32$' "$f128_summary"
    \\rg -q '[[:space:]]zig_struct_f32a8_f32a8$' "$f128_summary"
    \\rg -q '[[:space:]]zig_ret_struct_f32a8_f32a8$' "$f128_summary"
    \\rg -q '[[:space:]]zig_struct_f32a8$' "$f128_summary"
    \\rg -q '[[:space:]]zig_ret_struct_f32a8$' "$f128_summary"
    \\rg -q '[[:space:]]zig_struct_f64$' "$f128_summary"
    \\rg -q '[[:space:]]zig_ret_struct_f64$' "$f128_summary"
    \\rg -q '[[:space:]]zig_struct_f32$' "$f128_summary"
    \\rg -q '[[:space:]]zig_ret_struct_f32$' "$f128_summary"
    \\rg -q '[[:space:]]zig_struct_u64_u64_8$' "$f128_summary"
    \\rg -q '[[:space:]]zig_struct_u64_u64_7$' "$f128_summary"
    \\rg -q '[[:space:]]zig_struct_u64_u64_6$' "$f128_summary"
    \\rg -q '[[:space:]]zig_struct_u64_u64_5$' "$f128_summary"
    \\rg -q '[[:space:]]zig_struct_u64_u64_4$' "$f128_summary"
    \\rg -q '[[:space:]]zig_struct_u64_u64_3$' "$f128_summary"
    \\rg -q '[[:space:]]zig_struct_u64_u64_2$' "$f128_summary"
    \\rg -q '[[:space:]]zig_struct_u64_u64_1$' "$f128_summary"
    \\rg -q '[[:space:]]zig_struct_u64_u64_0$' "$f128_summary"
    \\rg -q '[[:space:]]zig_ret_struct_u64_u64$' "$f128_summary"
    \\rg -q '[[:space:]]zig_struct_u64$' "$f128_summary"
    \\rg -q '[[:space:]]zig_ret_struct_u64$' "$f128_summary"
    \\rg -q '[[:space:]]zig_struct_u32$' "$f128_summary"
    \\rg -q '[[:space:]]zig_ret_struct_u32$' "$f128_summary"
    \\rg -q '[[:space:]]zig_struct_u16$' "$f128_summary"
    \\rg -q '[[:space:]]zig_ret_struct_u16$' "$f128_summary"
    \\rg -q '[[:space:]]zig_struct_u8$' "$f128_summary"
    \\rg -q '[[:space:]]zig_ret_struct_u8$' "$f128_summary"
    \\rg -q '[[:space:]]zig_cmultd_comp$' "$f128_summary"
    \\rg -q '[[:space:]]zig_cmultf_comp$' "$f128_summary"
    \\rg -q '[[:space:]]zig_cmultd$' "$f128_summary"
    \\rg -q '[[:space:]]zig_cmultf$' "$f128_summary"
    \\rg -q '[[:space:]]zig_bool$' "$f128_summary"
    \\rg -q '[[:space:]]zig_ptr$' "$f128_summary"
    \\rg -q '[[:space:]]zig_f64$' "$f128_summary"
    \\rg -q '[[:space:]]zig_f32$' "$f128_summary"
    \\rg -q '[[:space:]]zig_five_floats$' "$f128_summary"
    \\rg -q '[[:space:]]zig_struct_u128$' "$f128_summary"
    \\rg -q '[[:space:]]zig_struct_i128$' "$f128_summary"
    \\rg -q '[[:space:]]zig_i64$' "$f128_summary"
    \\rg -q '[[:space:]]zig_i32$' "$f128_summary"
    \\rg -q '[[:space:]]zig_i16$' "$f128_summary"
    \\rg -q '[[:space:]]zig_i8$' "$f128_summary"
    \\rg -q '[[:space:]]zig_u64$' "$f128_summary"
    \\rg -q '[[:space:]]zig_u32$' "$f128_summary"
    \\rg -q '[[:space:]]zig_u16$' "$f128_summary"
    \\rg -q '[[:space:]]zig_u8$' "$f128_summary"
    \\rg -q '[[:space:]]zig_five_integers$' "$f128_summary"
    \\rg -q '[[:space:]]zig_panic$' "$f128_summary"
    \\rg -q '[[:space:]]__zllvm_f128_cmp0$' "$f128_summary"
    \\rg -q '[[:space:]]__zllvm_f128_ret1$' "$f128_summary"
    \\rg -q '[[:space:]]__zllvm_f128_struct_ret0$' "$f128_summary"
    \\rg -q '[[:space:]]__zllvm_f128_scalar_ret0$' "$f128_summary"
    \\rg -q 'R_X86_64_PLT32.*__eqtf2' "$f128_summary"
    \\rg -q 'R_X86_64_PC32.*__zllvm_f128_cmp0' "$f128_summary"
    \\rg -q 'R_X86_64_PC32.*__zllvm_f128_ret1' "$f128_summary"
    \\rg -q 'R_X86_64_PC32.*__zllvm_f128_struct_ret0' "$f128_summary"
    \\rg -q 'R_X86_64_PC32.*__zllvm_f128_scalar_ret0' "$f128_summary"
    \\rg -q 'R_X86_64_PLT32.*__eqtf2' "$f128_dump"
    \\rg -q 'movaps[[:space:]]+.*%xmm0' "$f128_dump"
    \\rg -q 'ucomisd[[:space:]]+%xmm1,%xmm0' "$f128_dump"
    \\rg -q 'movq[[:space:]]+%rax,%xmm0' "$f128_dump"
    \\rg -q 'movabs[[:space:]]+\$0x3f60000000000027,%rax' "$f128_dump"
    \\rg -q 'movabs[[:space:]]+\$0xbfd0000000000000,%rax' "$f128_dump"
    \\rg -q 'movabs[[:space:]]+\$0xf,%rax' "$f128_dump"
    \\rg -q 'movabs[[:space:]]+\$0x4d2,%rax' "$f128_dump"
    \\rg -q 'movabs[[:space:]]+\$0x44a7200000000064,%rdx' "$f128_dump"
    \\rg -q 'movabs[[:space:]]+\$0x42c80000000004d2,%rax' "$f128_dump"
    \\rg -q 'movabs[[:space:]]+\$0x44a72000,%rdx' "$f128_dump"
    \\rg -q 'movabs[[:space:]]+\$0x200000001,%rax' "$f128_dump"
    \\rg -q 'movabs[[:space:]]+\$0x3,%rdx' "$f128_dump"
    \\rg -q 'movabs[[:space:]]+\$0xffffffffffffffff,%rax' "$f128_dump"
    \\rg -q 'mov[[:alpha:]]*[[:space:]]+\$0xffffffff,%eax' "$f128_dump"
    \\rg -q 'mov[[:alpha:]]*[[:space:]]+\$0xffff,%eax' "$f128_dump"
    \\rg -q 'mov[[:alpha:]]*[[:space:]]+\$0xff,%eax' "$f128_dump"
    \\rg -q 'mov[[:alpha:]]*[[:space:]]+\$0x1,%eax' "$f128_dump"
    \\rg -q 'movq[[:space:]]+%xmm3,%rax' "$f128_dump"
    \\rg -q 'movabs[[:space:]]+\$0x4170000041a80000,%rdx' "$f128_dump"
    \\rg -q 'cmp[[:space:]]+%rdx,%rax' "$f128_dump"
    \\rg -q 'movabs[[:space:]]+\$0xbd000000b2,%rax' "$f128_dump"
    \\rg -q 'cmp[[:space:]]+%rax,%rdx' "$f128_dump"
    \\rg -q 'mov[[:alpha:]]*[[:space:]]+0x20\(%rsi\),%eax' "$f128_dump"
    \\rg -q 'movq[[:space:]]+\$0x17,0x18\(%rdi\)' "$f128_dump"
    \\rg -q 'movb[[:space:]]+\$0x18,0x20\(%rdi\)' "$f128_dump"
    \\rg -q 'movabs[[:space:]]+\$0x44a7200000000064,%rax' "$f128_dump"
    \\rg -q 'cmp[[:space:]]+%rax,%rsi' "$f128_dump"
    \\rg -q 'movabs[[:space:]]+\$0x53900000064,%rax' "$f128_dump"
    \\rg -q 'movabs[[:space:]]+\$0x2,%rax' "$f128_dump"
    \\rg -q 'cmp[[:alpha:]]*[[:space:]]+\$0xe4,%dil' "$f128_dump"
    \\rg -q 'movabs[[:space:]]+\$0x200000001,%rax' "$f128_dump"
    \\rg -q 'cmp[[:space:]]+%ecx,%esi' "$f128_dump"
    \\rg -q 'cmp[[:alpha:]]*[[:space:]]+\$0x4030201,%eax' "$f128_dump"
    \\rg -q 'cmp[[:alpha:]]*[[:space:]]+\$0x44a72000,%eax' "$f128_dump"
    \\rg -q 'movabs[[:space:]]+\$0x400000003f800000,%rdx' "$f128_dump"
    \\rg -q 'cmp[[:alpha:]]*[[:space:]]+\$0x40400000,%eax' "$f128_dump"
    \\rg -q 'movabs[[:space:]]+\$0x400000003f800000,%rax' "$f128_dump"
    \\rg -q 'mov[[:alpha:]]*[[:space:]]+\$0x40400000,%eax' "$f128_dump"
    \\rg -q 'cmp[[:alpha:]]*[[:space:]]+\$0x40480000,%eax' "$f128_dump"
    \\rg -q 'cmp[[:alpha:]]*[[:space:]]+\$0x408c0000,%eax' "$f128_dump"
    \\rg -q 'cmp[[:alpha:]]*[[:space:]]+\$0x40b00000,%eax' "$f128_dump"
    \\rg -q 'movabs[[:space:]]+\$0x3fa00000,%rax' "$f128_dump"
    \\rg -q 'mov[[:alpha:]]*[[:space:]]+\$0x40300000,%eax' "$f128_dump"
    \\rg -q 'cmp[[:alpha:]]*[[:space:]]+\$0x40300000,%eax' "$f128_dump"
    \\rg -q 'cmp[[:alpha:]]*[[:space:]]+\$0x40600000,%eax' "$f128_dump"
    \\rg -q 'mov[[:alpha:]]*[[:space:]]+\$0x3fa00000,%eax' "$f128_dump"
    \\rg -q 'movabs[[:space:]]+\$0x4004000000000000,%rax' "$f128_dump"
    \\rg -q 'cmp[[:alpha:]]*[[:space:]]+\$0x40200000,%eax' "$f128_dump"
    \\rg -q 'mov[[:alpha:]]*[[:space:]]+\$0x40200000,%eax' "$f128_dump"
    \\rg -q 'mov[[:alpha:]]*[[:space:]]+0x18\(%rsp\),%rax' "$f128_dump"
    \\rg -q 'mov[[:alpha:]]*[[:space:]]+0x20\(%rsp\),%rax' "$f128_dump"
    \\rg -q 'mov[[:alpha:]]*[[:space:]]+0x10\(%rsp\),%rax' "$f128_dump"
    \\rg -q 'mov[[:alpha:]]*[[:space:]]+0x8\(%rsp\),%rax' "$f128_dump"
    \\rg -q 'movabs[[:space:]]+\$0x13,%rdx' "$f128_dump"
    \\rg -q 'movabs[[:space:]]+\$0x14,%rdx' "$f128_dump"
    \\rg -q 'movabs[[:space:]]+\$0x9,%rdx' "$f128_dump"
    \\rg -q 'movabs[[:space:]]+\$0x11,%rdx' "$f128_dump"
    \\rg -q 'movabs[[:space:]]+\$0x12,%rdx' "$f128_dump"
    \\rg -q 'movabs[[:space:]]+\$0x8,%rdx' "$f128_dump"
    \\rg -q 'movabs[[:space:]]+\$0xf,%rdx' "$f128_dump"
    \\rg -q 'movabs[[:space:]]+\$0x10,%rdx' "$f128_dump"
    \\rg -q 'movabs[[:space:]]+\$0x7,%rdx' "$f128_dump"
    \\rg -q 'mov[[:alpha:]]*[[:space:]]+0x8\(%r9\),%rax' "$f128_dump"
    \\rg -q 'movabs[[:space:]]+\$0xd,%rdx' "$f128_dump"
    \\rg -q 'movabs[[:space:]]+\$0xe,%rdx' "$f128_dump"
    \\rg -q 'movabs[[:space:]]+\$0x6,%rdx' "$f128_dump"
    \\rg -q 'movabs[[:space:]]+\$0xb,%rax' "$f128_dump"
    \\rg -q 'movabs[[:space:]]+\$0xc,%rax' "$f128_dump"
    \\rg -q 'movabs[[:space:]]+\$0x5,%rdx' "$f128_dump"
    \\rg -q 'movabs[[:space:]]+\$0x9,%rax' "$f128_dump"
    \\rg -q 'movabs[[:space:]]+\$0xa,%rax' "$f128_dump"
    \\rg -q 'movabs[[:space:]]+\$0x4,%rax' "$f128_dump"
    \\rg -q 'movabs[[:space:]]+\$0x7,%rax' "$f128_dump"
    \\rg -q 'movabs[[:space:]]+\$0x8,%rax' "$f128_dump"
    \\rg -q 'movabs[[:space:]]+\$0x3,%rax' "$f128_dump"
    \\rg -q 'movabs[[:space:]]+\$0x5,%rax' "$f128_dump"
    \\rg -q 'movabs[[:space:]]+\$0x6,%rax' "$f128_dump"
    \\rg -q 'movabs[[:space:]]+\$0x2,%rax' "$f128_dump"
    \\rg -q 'movabs[[:space:]]+\$0x4,%rax' "$f128_dump"
    \\rg -q 'movabs[[:space:]]+\$0x1,%rax' "$f128_dump"
    \\rg -q 'movabs[[:space:]]+\$0x2,%rdx' "$f128_dump"
    \\rg -q 'movabs[[:space:]]+\$0x15,%rax' "$f128_dump"
    \\rg -q 'movabs[[:space:]]+\$0x13,%rax' "$f128_dump"
    \\rg -q 'mov[[:alpha:]]*[[:space:]]+%edi,%eax' "$f128_dump"
    \\rg -q 'cmp[[:alpha:]]*[[:space:]]+\$0xe,%eax' "$f128_dump"
    \\rg -q 'movabs[[:space:]]+\$0xf,%rax' "$f128_dump"
    \\rg -q 'mov[[:alpha:]]*[[:space:]]+\$0xd,%eax' "$f128_dump"
    \\rg -q 'cmp[[:alpha:]]*[[:space:]]+\$0x8,%di' "$f128_dump"
    \\rg -q 'movabs[[:space:]]+\$0x9,%rax' "$f128_dump"
    \\rg -q 'mov[[:alpha:]]*[[:space:]]+\$0x7,%eax' "$f128_dump"
    \\rg -q 'cmp[[:alpha:]]*[[:space:]]+\$0x2,%dil' "$f128_dump"
    \\rg -q 'movabs[[:space:]]+\$0x3,%rax' "$f128_dump"
    \\rg -q 'mov[[:alpha:]]*[[:space:]]+\$0x1,%eax' "$f128_dump"
    \\rg -q 'movabs[[:space:]]+\$0x3ff4000000000000,%rax' "$f128_dump"
    \\rg -q 'movabs[[:space:]]+\$0x4004cccccccccccd,%rax' "$f128_dump"
    \\rg -q 'movabs[[:space:]]+\$0x402699999999999a,%rax' "$f128_dump"
    \\rg -q 'movabs[[:space:]]+\$0xbff8000000000000,%rax' "$f128_dump"
    \\rg -q 'movabs[[:space:]]+\$0x3ff8000000000000,%rax' "$f128_dump"
    \\rg -q 'movabs[[:space:]]+\$0x402b000000000000,%rax' "$f128_dump"
    \\rg -q 'ucomisd[[:space:]]+%xmm1,%xmm0' "$f128_dump"
    \\rg -q 'ucomisd[[:space:]]+%xmm0,%xmm1' "$f128_dump"
    \\rg -q 'ucomisd[[:space:]]+%xmm1,%xmm2' "$f128_dump"
    \\rg -q 'ucomisd[[:space:]]+%xmm1,%xmm3' "$f128_dump"
    \\rg -q 'cmp[[:alpha:]]*[[:space:]]+\$0x3fa00000,%eax' "$f128_dump"
    \\rg -q 'cmp[[:alpha:]]*[[:space:]]+\$0x40266666,%eax' "$f128_dump"
    \\rg -q 'cmp[[:alpha:]]*[[:space:]]+\$0x4134cccd,%eax' "$f128_dump"
    \\rg -q 'cmp[[:alpha:]]*[[:space:]]+\$0xbfc00000,%eax' "$f128_dump"
    \\rg -q 'movabs[[:space:]]+\$0x415800003fc00000,%rax' "$f128_dump"
    \\rg -q 'movabs[[:space:]]+\$0x402666663fa00000,%rdx' "$f128_dump"
    \\rg -q 'movabs[[:space:]]+\$0xbfc000004134cccd,%rdx' "$f128_dump"
    \\rg -q 'cmp[[:alpha:]]*[[:space:]]+\$0x0,%dil' "$f128_dump"
    \\rg -q 'movabs[[:space:]]+\$0xdeadbeef,%rax' "$f128_dump"
    \\rg -q 'movabs[[:space:]]+\$0x404c63d70a3d70a4,%rax' "$f128_dump"
    \\rg -q 'mov[[:alpha:]]*[[:space:]]+\$0x414570a4,%eax' "$f128_dump"
    \\rg -q 'movq[[:space:]]+%xmm4,%rax' "$f128_dump"
    \\rg -q 'cmp[[:alpha:]]*[[:space:]]+\$0x40a00000,%eax' "$f128_dump"
    \\rg -q 'movabs[[:space:]]+\$0xfffffffffffffffc,%rax' "$f128_dump"
    \\rg -q 'movabs[[:space:]]+\$0xfffffffffffffffa,%rax' "$f128_dump"
    \\rg -q 'cmp[[:alpha:]]*[[:space:]]+\$0xfffffffd,%eax' "$f128_dump"
    \\rg -q 'mov[[:alpha:]]*[[:space:]]+%r8d,%eax' "$f128_dump"
    \\rg -q 'cmp[[:alpha:]]*[[:space:]]+\$0x5a,%eax' "$f128_dump"
    \\rg -q 'mov[[:alpha:]]*[[:space:]]+0x20\(%rdi\),%eax' "$f128_dump"
    \\rg -q 'movabs[[:space:]]+\$0x5,%rdx' "$f128_dump"
    \\rg -q 'cmp[[:alpha:]]*[[:space:]]+\$0xf,%dil' "$f128_dump"
    \\rg -q 'ucomiss[[:space:]]+%xmm1,%xmm0' "$f128_dump"
    \\rg -q 'jp[[:space:]]+' "$f128_dump"
    \\rg -q '[[:space:]]ud2' "$f128_dump"
;

const cases = [_]Case{
    .{
        .id = "export_keyword_vram_store",
        .fixture = "test/distribution/releasesmall_x86_64/inputs/export_keyword_vram_store.ll",
        .summary_patterns = &.{ "[[:space:]]testPackedStuff$", "[[:space:]]writeToVRam$" },
        .dump_patterns = &.{"movb[[:space:]]+\\$0x58,0x20000000"},
    },
    .{
        .id = "sizeof_typeof_unreachable_stubs",
        .fixture = "test/distribution/releasesmall_x86_64/inputs/sizeof_typeof_unreachable_stubs.ll",
        .summary_patterns = &.{ "[[:space:]]c_fopen$", "[[:space:]]c_ftell$", "[[:space:]]c_fputs$", "[[:space:]]c_printf$" },
        .dump_patterns = &.{"[[:space:]]ud2"},
    },
    .{
        .id = "c_abi_main_f128_sret",
        .fixture = "test/distribution/releasesmall_x86_64/inputs/c_abi_main_f128_sret.ll",
        .embedded_checks = f128_checks,
    },
    .{
        .id = "address_space_start_trampoline",
        .fixture = "test/distribution/releasesmall_x86_64/inputs/address_space_start_trampoline.ll",
        .summary_patterns = &.{ "[[:space:]]_start$", "[[:space:]]start\\._start$", "[[:space:]]start\\.posixCallMainAndExit$", "R_X86_64_PLT32.*start\\.posixCallMainAndExit" },
        .dump_patterns = &.{ "xor[[:alpha:]]*[[:space:]]+%ebp,%ebp", "mov[[:alpha:]]*[[:space:]]+%rsp,%rdi", "and[[:alpha:]]*[[:space:]]+\\$0xfffffffffffffff0,%rsp", "R_X86_64_PLT32[[:space:]]+start\\.posixCallMainAndExit" },
    },
    .{
        .id = "array_in_anon_struct_getauxval",
        .fixture = "test/distribution/releasesmall_x86_64/inputs/array_in_anon_struct_getauxval.ll",
        .summary_patterns = &.{ "[[:space:]]getauxval$", "[[:space:]]os\\.linux\\.getauxvalImpl$", "[[:space:]]os\\.linux\\.elf_aux_maybe$", "R_X86_64_PC32.*os\\.linux\\.elf_aux_maybe" },
        .dump_patterns = &.{ "mov[[:alpha:]]*[[:space:]]+0x0\\(%rip\\),%rax", "test[[:alpha:]]*[[:space:]]+%rax,%rax", "mov[[:alpha:]]*[[:space:]]+\\(%rax\\),%rdx", "cmp[[:alpha:]]*[[:space:]]+%rdi,%rdx", "add[[:alpha:]]*[[:space:]]+\\$0x10,%rax", "mov[[:alpha:]]*[[:space:]]+0x8\\(%rax\\),%rax" },
    },
    .{
        .id = "compile_errors_illegal_operation_on_logical_ptr_elem_ptr",
        .fixture = "test/distribution/releasesmall_x86_64/inputs/compile_errors_illegal_operation_on_logical_ptr_elem_ptr.ll",
        .summary_patterns = &.{ "[[:space:]]elemVal$", "[[:space:]]elemPtr$", "[[:space:]]illegal_operation_on_logical_ptr\\.elemPtr$" },
        .dump_patterns = &.{"[[:space:]]ud2"},
    },
    .{
        .id = "inherit_want_safety_i64_return",
        .fixture = "test/distribution/releasesmall_x86_64/inputs/inherit_want_safety_i64_return.ll",
        .summary_patterns = &.{ "[[:space:]]entry$", "[[:space:]]inherit_want_safety\\.entry$" },
        .dump_patterns = &.{ "movabs[[:space:]]+\\$0x4,%rax", "[[:space:]]ret" },
    },
    .{
        .id = "no_compile_panic_for_unchecked_arith_umul_fix_sat_i64",
        .fixture = "test/distribution/releasesmall_x86_64/inputs/no_compile_panic_for_unchecked_arith_umul_fix_sat_i64.ll",
        .summary_patterns = &.{ "[[:space:]]entry$", "[[:space:]]no_compile_panic_for_unchecked_arith\\.entry$" },
        .dump_patterns = &.{ "movabs[[:space:]]+\\$0x0,%rax", "[[:space:]]ret" },
    },
    .{
        .id = "standalone_compile_asm_main_unreachable",
        .fixture = "test/distribution/releasesmall_x86_64/inputs/standalone_compile_asm_main_unreachable.ll",
        .summary_patterns = &.{ "[[:space:]]main$", "[[:space:]]main\\.main$" },
        .dump_patterns = &.{"[[:space:]]ud2"},
    },
    .{
        .id = "standalone_extern_exports_hidden_access",
        .fixture = "test/distribution/releasesmall_x86_64/inputs/standalone_extern_exports_hidden_access.ll",
        .summary_patterns = &.{ "[[:space:]]getHidden$", "[[:space:]]updateHidden$", "[[:space:]]exports\\.getHidden$", "[[:space:]]exports\\.updateHidden$", "[[:space:]]exports\\.hidden$", "R_X86_64_PC32.*exports\\.hidden" },
        .dump_patterns = &.{ "mov[[:alpha:]]*[[:space:]]+0x0\\(%rip\\),%eax", "mov[[:alpha:]]*[[:space:]]+%edi,%eax", "mov[[:alpha:]]*[[:space:]]+%eax,0x0\\(%rip\\)" },
    },
    .{
        .id = "standalone_install_raw_hex_start_loop",
        .fixture = "test/distribution/releasesmall_x86_64/inputs/standalone_install_raw_hex_start_loop.ll",
        .summary_patterns = &.{ "[[:space:]]_start$", "[[:space:]]main\\._start$" },
        .dump_patterns = &.{ "jmp[[:space:]]+0 <_start>", "[[:space:]]ud2" },
    },
    .{
        .id = "standalone_libfuzzer_runner_futex_wait",
        .fixture = "test/distribution/releasesmall_x86_64/inputs/standalone_libfuzzer_runner_futex_wait.ll",
        .summary_patterns = &.{ "[[:space:]]runner_futex_wait$", "[[:space:]]main\\.runner_futex_wait$" },
        .dump_patterns = &.{ "mov[[:alpha:]]*[[:space:]]+\\$0x0,%eax", "[[:space:]]ret" },
    },
    .{
        .id = "standalone_libfuzzer_runner_test_name",
        .fixture = "test/distribution/releasesmall_x86_64/inputs/standalone_libfuzzer_runner_test_name.ll",
        .summary_patterns = &.{ "[[:space:]]runner_test_name$", "[[:space:]]main\\.runner_test_name$", "[[:space:]]__anon_16879$", "R_X86_64_PC32.*__anon_16879" },
        .dump_patterns = &.{ "lea[[:alpha:]]*[[:space:]]+0x0\\(%rip\\),%rax", "movabs[[:space:]]+\\$0x4,%rdx", "[[:space:]]ret" },
    },
    .{
        .id = "standalone_libfuzzer_runner_test_run",
        .fixture = "test/distribution/releasesmall_x86_64/inputs/standalone_libfuzzer_runner_test_run.ll",
        .summary_patterns = &.{ "[[:space:]]runner_test_run$", "[[:space:]]main\\.runner_test_run$", "[[:space:]]__anon_11775$", "[[:space:]]__anon_16031$", "R_X86_64_PC32.*main\\.testOne", "R_X86_64_PC32.*__anon_11775", "R_X86_64_PC32.*__anon_16031", "R_X86_64_PLT32.*fuzzer_set_test", "R_X86_64_PLT32.*fuzzer_new_input", "R_X86_64_PLT32.*fuzzer_start_test" },
        .dump_patterns = &.{ "lea[[:alpha:]]*[[:space:]]+0x0\\(%rip\\),%rdi", "movabs[[:space:]]+\\$0x5,%rsi", "call", "[[:space:]]ret" },
    },
    .{
        .id = "base64_table_lookup",
        .fixture = "test/distribution/releasesmall_x86_64/inputs/base64_table_lookup.ll",
        .summary_patterns = &.{ "[[:space:]]base64_table_lookup$", "[[:space:]]base64\\.table_lookup$", "[[:space:]]__anon_base64_table$", "R_X86_64_PC32.*__anon_base64_table" },
        .dump_patterns = &.{ "lea[[:alpha:]]*[[:space:]]+0x0\\(%rip\\),%rax", "movzbl[[:space:]]+%dil,%edi", "movzbl[[:space:]]+\\(%rax,%rdi,1\\),%eax", "[[:space:]]ret" },
    },
    .{
        .id = "standalone_mix_c_files_add_zig",
        .fixture = "test/distribution/releasesmall_x86_64/inputs/standalone_mix_c_files_add_zig.ll",
        .summary_patterns = &.{ "[[:space:]]add_zig$", "[[:space:]]main\\.add_zig$", "[[:space:]]main\\.zig_k$", "[[:space:]]zig_k$", "[[:space:]]C_k$", "R_X86_64_PC32.*main\\.zig_k", "R_X86_64_TPOFF32.*C_k" },
        .dump_patterns = &.{ "mov[[:alpha:]]*[[:space:]]+0x0\\(%rip\\),%eax", "add[[:alpha:]]*[[:space:]]+%edi,%eax", "add[[:alpha:]]*[[:space:]]+%fs:0x0,%eax", "[[:space:]]ret" },
    },
    .{
        .id = "standalone_mix_c_files_add_may_panic",
        .fixture = "test/distribution/releasesmall_x86_64/inputs/standalone_mix_c_files_add_may_panic.ll",
        .summary_patterns = &.{ "[[:space:]]add_may_panic$", "[[:space:]]main\\.add_may_panic$", "[[:space:]]main\\.zig_k$", "[[:space:]]__anon_14658$", "R_X86_64_PC32.*main\\.zig_k", "R_X86_64_PC32.*__anon_14658", "R_X86_64_PLT32.*debug\\.defaultPanic" },
        .dump_patterns = &.{ "test[[:alpha:]]*[[:space:]]+%edi,%edi", "js[[:space:]]+", "lea[[:alpha:]]*[[:space:]]+0x0\\(%rip\\),%rdi", "movabs[[:space:]]+\\$0xc,%rsi", "call", "ud2" },
    },
};

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;

    const target_env = try common.getEnvOwnedOrNull(allocator, init.minimal.environ, "TARGET");
    defer if (target_env) |value| allocator.free(value);
    const target = target_env orelse "x86_64-unknown-linux-gnu";

    const temp = try common.TempDir.init(allocator, io, "releasesmall_object_m3");
    defer temp.deinit(allocator, io);

    var stdout_buffer: [512]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    for (cases) |case| {
        try runCase(allocator, io, temp, target, case);
        try stdout_writer.interface.print("ok distribution releasesmall object {s}\n", .{case.id});
        try stdout_writer.interface.flush();
    }
}

fn runCase(
    allocator: std.mem.Allocator,
    io: std.Io,
    temp: common.TempDir,
    target: []const u8,
    case: Case,
) !void {
    const object = try common.allocTempFile(allocator, temp, case.id, ".o");
    defer allocator.free(object);
    const summary = try common.allocTempFile(allocator, temp, case.id, ".readelf.txt");
    defer allocator.free(summary);
    const dump = try common.allocTempFile(allocator, temp, case.id, ".objdump.txt");
    defer allocator.free(dump);

    const target_arg = try std.fmt.allocPrint(allocator, "--target={s}", .{target});
    defer allocator.free(target_arg);
    const emit_argv = [_][]const u8{ "zig", "build", "run", "--", "--emit=obj", target_arg, "--input-limit=67108864", case.fixture };
    try common.runToFile(allocator, io, &emit_argv, "zig build run", object);

    const readelf_argv = [_][]const u8{ "readelf", "-W", "-h", "-S", "-s", "-r", object };
    try common.runToFile(allocator, io, &readelf_argv, "readelf", summary);
    const objdump_argv = [_][]const u8{ "objdump", "-dr", object };
    try common.runToFile(allocator, io, &objdump_argv, "objdump", dump);

    try expectRegex(allocator, io, summary, "Type:[[:space:]]+REL");
    try expectRegex(allocator, io, summary, "Machine:[[:space:]]+Advanced Micro Devices X86-64");
    for (case.summary_patterns) |pattern| try expectRegex(allocator, io, summary, pattern);
    for (case.dump_patterns) |pattern| try expectRegex(allocator, io, dump, pattern);
    if (case.embedded_checks) |checks| try runEmbeddedChecks(allocator, io, summary, dump, checks);
}

fn runEmbeddedChecks(
    allocator: std.mem.Allocator,
    io: std.Io,
    summary: []const u8,
    dump: []const u8,
    checks: []const u8,
) !void {
    var lines = std.mem.splitScalar(u8, checks, '\n');
    while (lines.next()) |raw_line| {
        const line = std.mem.trim(u8, raw_line, " \t\r");
        if (line.len == 0) continue;

        const first_quote = std.mem.indexOfScalar(u8, line, '\'') orelse return error.MalformedEmbeddedCheck;
        const rest = line[first_quote + 1 ..];
        const second_quote = std.mem.indexOfScalar(u8, rest, '\'') orelse return error.MalformedEmbeddedCheck;
        const pattern = rest[0..second_quote];
        const path = if (std.mem.endsWith(u8, line, "\"$f128_summary\""))
            summary
        else if (std.mem.endsWith(u8, line, "\"$f128_dump\""))
            dump
        else
            return error.MalformedEmbeddedCheck;
        try expectRegex(allocator, io, path, pattern);
    }
}

fn expectRegex(allocator: std.mem.Allocator, io: std.Io, path: []const u8, pattern: []const u8) !void {
    try common.expectRegex(allocator, io, path, pattern);
}
