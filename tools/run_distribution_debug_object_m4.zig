const std = @import("std");
const common = @import("tool_common.zig");

const Case = struct {
    id: []const u8,
    fixture: []const u8,
    symbol: []const u8,
    summary_patterns: []const []const u8 = &.{},
    dump_patterns: []const []const u8 = &.{},
};

const expected_root = "test/zig/expected/";
const debug_root = "test/distribution/debug_x86_64/inputs/";

const cases = [_]Case{
    .{
        .id = "debug_call_chain",
        .fixture = expected_root ++ "debug_call_chain.reduced.ll",
        .symbol = "debug_call_chain",
        .summary_patterns = &.{ "[[:space:]]debug_callee$", "R_X86_64_PLT32.*debug_callee" },
        .dump_patterns = &.{"add[[:alpha:]]*[[:space:]]+\\$0x1,%eax"},
    },
    .{
        .id = "debug_declare_intrinsic",
        .fixture = expected_root ++ "debug_declare_intrinsic.reduced.ll",
        .symbol = "debug_declare",
        .summary_patterns = &.{"There are no relocations in this file"},
        .dump_patterns = &.{"[[:space:]]ret"},
    },
    .{
        .id = "debug_loop_sum",
        .fixture = expected_root ++ "debug_loop_sum.reduced.ll",
        .symbol = "debug_loop_sum",
        .dump_patterns = &.{ "[[:space:]]test[[:space:]]+%edi,%edi", "[[:space:]]js[[:space:]]+", "[[:space:]]jne[[:space:]]+" },
    },
    .{
        .id = "debug_metadata",
        .fixture = expected_root ++ "debug_metadata.reduced.ll",
        .symbol = "debug_add",
        .dump_patterns = &.{"add[[:alpha:]]*[[:space:]]+\\$0x1,%eax"},
    },
    .{
        .id = "debug_scope_branch",
        .fixture = expected_root ++ "debug_scope_branch.reduced.ll",
        .symbol = "debug_scope_branch",
        .dump_patterns = &.{ "[[:space:]]test[[:space:]]+%dil,%dil", "[[:space:]]jne[[:space:]]+", "add[[:alpha:]]*[[:space:]]+\\$0x1,%eax" },
    },
    .{
        .id = "debug_value_intrinsic",
        .fixture = expected_root ++ "debug_value_intrinsic.reduced.ll",
        .symbol = "debug_value",
        .dump_patterns = &.{"[[:space:]]mov[[:space:]]+%edi,%eax"},
    },
    .{
        .id = "debug_pointers_volatile_roundtrip",
        .fixture = expected_root ++ "debug_pointers_volatile_roundtrip.reduced.ll",
        .symbol = "volatile_roundtrip",
        .summary_patterns = &.{"There are no relocations in this file"},
        .dump_patterns = &.{ "mov[[:alpha:]]*[[:space:]]+%esi,\\(%rdi\\)", "mov[[:alpha:]]*[[:space:]]+\\(%rdi\\),%eax" },
    },
    .{
        .id = "debug_sizeof_typeof_c_unreachable",
        .fixture = expected_root ++ "debug_sizeof_typeof_c_unreachable.reduced.ll",
        .symbol = "c_fopen",
        .summary_patterns = &.{ "[[:space:]]c_ftell$", "[[:space:]]c_fputs$", "[[:space:]]c_printf$" },
        .dump_patterns = &.{"ud2"},
    },
    .{
        .id = "debug_c_abi_f128_sret",
        .fixture = expected_root ++ "debug_c_abi_f128_sret.reduced.ll",
        .symbol = "zig_f128_f128_struct",
        .summary_patterns = &.{"R_X86_64_PLT32.*__eqtf2"},
        .dump_patterns = &.{"ud2"},
    },
    .{
        .id = "logical_pointer_compile_error_o0",
        .fixture = debug_root ++ "logical_pointer_compile_error_o0.ll",
        .symbol = "ptrIntArithmetic",
        .summary_patterns = &.{ "[[:space:]]ptrPtrArithmetic$", "[[:space:]]ptrFromInt$", "[[:space:]]intFromPtr$", "[[:space:]]elemVal$", "[[:space:]]elemPtr$", "[[:space:]]illegal_operation_on_logical_ptr\\.ptrIntArithmetic$", "[[:space:]]illegal_operation_on_logical_ptr\\.elemPtr$" },
        .dump_patterns = &.{"[[:space:]]ret"},
    },
    .{
        .id = "spirv_merge_logical_pointers_o0",
        .fixture = debug_root ++ "spirv_merge_logical_pointers_o0.ll",
        .symbol = "a",
        .summary_patterns = &.{"[[:space:]]spirv_merge_logical_pointers\\.a$"},
        .dump_patterns = &.{"[[:space:]]ret"},
    },
    .{
        .id = "inherit_want_safety_o0",
        .fixture = debug_root ++ "inherit_want_safety_o0.ll",
        .symbol = "entry",
        .summary_patterns = &.{"[[:space:]]inherit_want_safety\\.entry$"},
        .dump_patterns = &.{ "movabs[[:alpha:]]*[[:space:]]+\\$0x4,%rax", "[[:space:]]ret" },
    },
    .{
        .id = "no_compile_panic_unchecked_arith_o0",
        .fixture = debug_root ++ "no_compile_panic_unchecked_arith_o0.ll",
        .symbol = "entry",
        .summary_patterns = &.{"[[:space:]]no_compile_panic_for_unchecked_arith\\.entry$"},
        .dump_patterns = &.{ "movabs[[:alpha:]]*[[:space:]]+\\$0x0,%rax", "[[:space:]]ret" },
    },
    .{
        .id = "compile_asm_panic_o0",
        .fixture = debug_root ++ "compile_asm_panic_o0.ll",
        .symbol = "main",
        .summary_patterns = &.{"[[:space:]]main\\.main$"},
        .dump_patterns = &.{"ud2"},
    },
    .{
        .id = "issue_339_error_success_o0",
        .fixture = debug_root ++ "issue_339_error_success_o0.ll",
        .symbol = "foo",
        .summary_patterns = &.{"[[:space:]]test\\.foo$"},
        .dump_patterns = &.{"[[:space:]]ret"},
    },
    .{
        .id = "libfuzzer_runner_o0",
        .fixture = debug_root ++ "libfuzzer_runner_o0.ll",
        .symbol = "runner_test_run",
        .summary_patterns = &.{ "[[:space:]]runner_broadcast_input$", "[[:space:]]runner_futex_wake$", "[[:space:]]runner_futex_wait$", "[[:space:]]runner_stop_input_poller$", "[[:space:]]runner_start_input_poller$", "[[:space:]]runner_test_name$", "[[:space:]]main\\.runner_test_run$", "R_X86_64_PC32.*main\\.testOne", "R_X86_64_PLT32.*fuzzer_set_test", "R_X86_64_PLT32.*fuzzer_new_input", "R_X86_64_PLT32.*fuzzer_start_test" },
        .dump_patterns = &.{"[[:space:]]ret"},
    },
    .{
        .id = "load_dynamic_library_add_o0",
        .fixture = debug_root ++ "load_dynamic_library_add_o0.ll",
        .symbol = "add",
        .summary_patterns = &.{ "[[:space:]]add\\.add$", "R_X86_64_PLT32.*debug\\.FullPanic\\(\\(function 'defaultPanic'\\)\\)\\.integerOverflow" },
        .dump_patterns = &.{ "[[:space:]]jo[[:space:]]+", "[[:space:]]ret" },
    },
    .{
        .id = "mix_c_files_main_o0",
        .fixture = debug_root ++ "mix_c_files_main_o0.ll",
        .symbol = "add_zig",
        .summary_patterns = &.{ "[[:space:]]add_may_panic$", "[[:space:]]zig_k$", "R_X86_64_PC32.*main\\.zig_k", "R_X86_64_TPOFF32.*C_k", "R_X86_64_PLT32.*debug\\.FullPanic\\(\\(function 'defaultPanic'\\)\\)\\.integerOverflow", "R_X86_64_PLT32.*debug\\.defaultPanic" },
        .dump_patterns = &.{ "[[:space:]]jo[[:space:]]+", "[[:space:]]js[[:space:]]+", "ud2" },
    },
    .{
        .id = "shared_library_mathtest_add_o0",
        .fixture = debug_root ++ "shared_library_mathtest_add_o0.ll",
        .symbol = "add",
        .summary_patterns = &.{ "[[:space:]]mathtest\\.add$", "R_X86_64_PLT32.*debug\\.FullPanic\\(\\(function 'defaultPanic'\\)\\)\\.integerOverflow" },
        .dump_patterns = &.{ "[[:space:]]jo[[:space:]]+", "[[:space:]]ret" },
    },
};

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;

    const target_env = try getEnvOwnedOrNull(allocator, init.minimal.environ, "TARGET");
    defer if (target_env) |value| allocator.free(value);
    const target = target_env orelse "x86_64-unknown-linux-gnu";

    const temp = try common.TempDir.init(allocator, io, "debug_object_m4");
    defer temp.deinit(allocator, io);

    var stdout_buffer: [512]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    for (cases) |case| {
        try runCase(allocator, io, temp, target, case);
        try stdout_writer.interface.print("ok distribution debug object {s}\n", .{case.id});
        try stdout_writer.interface.flush();
    }
    try stdout_writer.interface.print("ok distribution debug reduced object target={s}\n", .{target});
    try stdout_writer.interface.flush();
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

    try expectCommonObject(allocator, io, summary, case.symbol);
    for (case.summary_patterns) |pattern| try common.expectRegex(allocator, io, summary, pattern);
    for (case.dump_patterns) |pattern| try common.expectRegex(allocator, io, dump, pattern);
}

fn expectCommonObject(allocator: std.mem.Allocator, io: std.Io, summary: []const u8, symbol: []const u8) !void {
    try common.expectRegex(allocator, io, summary, "Type:[[:space:]]+REL");
    try common.expectRegex(allocator, io, summary, "Machine:[[:space:]]+Advanced Micro Devices X86-64");
    try common.expectRegex(allocator, io, summary, "\\.text");
    try common.expectRegex(allocator, io, summary, "\\.symtab");
    const symbol_pattern = try std.fmt.allocPrint(allocator, "[[:space:]]{s}$", .{symbol});
    defer allocator.free(symbol_pattern);
    try common.expectRegex(allocator, io, summary, symbol_pattern);
    try common.expectNoRegex(allocator, io, summary, "llvm\\.dbg");
}

fn getEnvOwnedOrNull(allocator: std.mem.Allocator, environ: std.process.Environ, name: []const u8) !?[]const u8 {
    return environ.getAlloc(allocator, name) catch |err| switch (err) {
        error.EnvironmentVariableMissing => null,
        else => err,
    };
}
