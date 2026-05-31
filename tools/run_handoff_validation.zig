const std = @import("std");
const common = @import("tool_common.zig");

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;

    const temp = try common.TempDir.init(allocator, io, "handoff_validation");
    defer temp.deinit(allocator, io);

    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);

    try runOptCase(allocator, io, temp, "scalar", "instcombine,dce", "test/opt/inputs/instcombine_safe_scalar.ll", "test/opt/expected/z_llvm/instcombine_safe_scalar.ll");
    try stdout_writer.interface.writeAll("ok handoff optimizer scalar [instcombine,dce]\n");
    try stdout_writer.interface.flush();

    try runOptCase(allocator, io, temp, "memory", "dse", "test/opt/inputs/dse_overwrite.ll", "test/opt/expected/z_llvm/dse_overwrite.ll");
    try stdout_writer.interface.writeAll("ok handoff optimizer memory [dse]\n");
    try stdout_writer.interface.flush();

    try runOptCase(allocator, io, temp, "loop", "licm", "test/opt/inputs/licm_invariant.ll", "test/opt/expected/z_llvm/licm_invariant.ll");
    try stdout_writer.interface.writeAll("ok handoff optimizer loop [licm]\n");
    try stdout_writer.interface.flush();

    try runOptCase(allocator, io, temp, "global", "globaldce", "test/opt/inputs/globaldce_basic.ll", "test/opt/expected/z_llvm/globaldce_basic.ll");
    try stdout_writer.interface.writeAll("ok handoff optimizer global [globaldce]\n");
    try stdout_writer.interface.flush();

    try runOptimizedCodegenCase(
        allocator,
        io,
        temp,
        "scalar_add_zero",
        "instcombine,dce",
        "test/handoff/inputs/scalar_add_zero.ll",
        "test/handoff/expected/ir/scalar_add_zero.ll",
        "test/handoff/expected/asm/scalar_add_zero.s",
        "test/handoff/expected/objdump/scalar_add_zero.txt",
    );
    try stdout_writer.interface.writeAll("ok handoff optimized-codegen scalar_add_zero [instcombine,dce]\n");
    try stdout_writer.interface.flush();

    try runEmptyModuleObjectCase(allocator, io, temp, "releasefast_empty_module", "test/handoff/inputs/releasefast_empty_module.ll");
    try stdout_writer.interface.writeAll("ok handoff empty-module object releasefast_empty_module\n");
    try stdout_writer.interface.flush();

    try runDebugHandoffCase(allocator, io, temp, "debug_o0_mathtest_checked_add", "test/distribution/debug_x86_64/inputs/shared_library_mathtest_add_o0.ll");
    try stdout_writer.interface.writeAll("ok handoff debug debug_o0_mathtest_checked_add\n");
    try stdout_writer.interface.flush();

    try runAsmCase(allocator, io, temp, "return_constant");
    try stdout_writer.interface.writeAll("ok handoff asm return_constant\n");
    try stdout_writer.interface.flush();
    try runAsmCase(allocator, io, temp, "call_one_arg");
    try stdout_writer.interface.writeAll("ok handoff asm call_one_arg\n");
    try stdout_writer.interface.flush();
    try runAsmCase(allocator, io, temp, "stack_slot");
    try stdout_writer.interface.writeAll("ok handoff asm stack_slot\n");
    try stdout_writer.interface.flush();
    try runAsmCase(allocator, io, temp, "call_stack_slot");
    try stdout_writer.interface.writeAll("ok handoff asm call_stack_slot\n");
    try stdout_writer.interface.flush();

    try runCodegenSmoke(allocator, io, "asm");
    try stdout_writer.interface.writeAll("ok handoff codegen asm smoke\n");
    try stdout_writer.interface.flush();
    try runCodegenSmoke(allocator, io, "objdump");
    try stdout_writer.interface.writeAll("ok handoff codegen objdump smoke\n");
    try stdout_writer.interface.flush();
    try runCodegenSmoke(allocator, io, "readelf");
    try stdout_writer.interface.writeAll("ok handoff codegen readelf smoke\n");
    try stdout_writer.interface.flush();
}

fn runOptCase(
    allocator: std.mem.Allocator,
    io: std.Io,
    temp: common.TempDir,
    id: []const u8,
    passes: []const u8,
    input: []const u8,
    expected: []const u8,
) !void {
    const actual = try common.allocTempFile(allocator, temp, id, ".ll");
    defer allocator.free(actual);
    const passes_arg = try std.fmt.allocPrint(allocator, "--passes={s}", .{passes});
    defer allocator.free(passes_arg);
    const argv = [_][]const u8{ "zig", "build", "run", "--", passes_arg, input };
    try common.runToFile(allocator, io, &argv, "zig build run", actual);
    try common.diffFiles(allocator, io, expected, actual);
}

fn runOptimizedCodegenCase(
    allocator: std.mem.Allocator,
    io: std.Io,
    temp: common.TempDir,
    id: []const u8,
    passes: []const u8,
    input: []const u8,
    expected_ir: []const u8,
    expected_asm: []const u8,
    expected_objdump: []const u8,
) !void {
    const optimized_ir = try common.allocTempFile(allocator, temp, id, ".optimized.ll");
    defer allocator.free(optimized_ir);
    const optimized_norm = try common.allocTempFile(allocator, temp, id, ".optimized.norm.ll");
    defer allocator.free(optimized_norm);
    const expected_norm = try common.allocTempFile(allocator, temp, id, ".expected.norm.ll");
    defer allocator.free(expected_norm);
    const llvm_ir = try common.allocTempFile(allocator, temp, id, ".llvm.ll");
    defer allocator.free(llvm_ir);
    const llvm_norm = try common.allocTempFile(allocator, temp, id, ".llvm.norm.ll");
    defer allocator.free(llvm_norm);
    const local_asm = try common.allocTempFile(allocator, temp, id, ".s");
    defer allocator.free(local_asm);
    const local_obj = try common.allocTempFile(allocator, temp, id, ".local.o");
    defer allocator.free(local_obj);
    const local_objdump = try common.allocTempFile(allocator, temp, id, ".local.objdump.txt");
    defer allocator.free(local_objdump);
    const llvm_obj = try common.allocTempFile(allocator, temp, id, ".llvm.o");
    defer allocator.free(llvm_obj);
    const llvm_objdump = try common.allocTempFile(allocator, temp, id, ".llvm.objdump.txt");
    defer allocator.free(llvm_objdump);

    const passes_arg = try std.fmt.allocPrint(allocator, "--passes={s}", .{passes});
    defer allocator.free(passes_arg);
    const z_opt_argv = [_][]const u8{ "zig", "build", "run", "--", passes_arg, input };
    try common.runToFile(allocator, io, &z_opt_argv, "zig build run", optimized_ir);
    try common.normalizeToFile(allocator, io, optimized_ir, optimized_norm);
    try common.normalizeToFile(allocator, io, expected_ir, expected_norm);
    try common.diffFiles(allocator, io, expected_norm, optimized_norm);

    const opt_passes_arg = try std.fmt.allocPrint(allocator, "-passes={s}", .{passes});
    defer allocator.free(opt_passes_arg);
    const opt_argv = [_][]const u8{ "opt-22", "-S", opt_passes_arg, input, "-o", llvm_ir };
    const opt_result = try common.runCapture(allocator, io, &opt_argv, "opt-22");
    common.freeRunResult(allocator, opt_result);
    try common.normalizeToFile(allocator, io, llvm_ir, llvm_norm);
    try common.diffFiles(allocator, io, llvm_norm, optimized_norm);

    const asm_argv = [_][]const u8{ "zig", "build", "run", "--", "--emit=asm", "--target=x86_64-unknown-linux-gnu", optimized_ir };
    try common.runToFile(allocator, io, &asm_argv, "zig build run", local_asm);
    try common.diffFiles(allocator, io, expected_asm, local_asm);

    const obj_argv = [_][]const u8{ "zig", "build", "run", "--", "--emit=obj", "--target=x86_64-unknown-linux-gnu", optimized_ir };
    try common.runToFile(allocator, io, &obj_argv, "zig build run", local_obj);
    try common.writeObjdumpTextSection(allocator, io, local_obj, local_objdump);
    try common.diffFiles(allocator, io, expected_objdump, local_objdump);

    const llc_argv = [_][]const u8{ "llc-22", "-filetype=obj", llvm_ir, "-o", llvm_obj };
    const llc_result = try common.runCapture(allocator, io, &llc_argv, "llc-22");
    common.freeRunResult(allocator, llc_result);
    try common.writeObjdumpTextSection(allocator, io, llvm_obj, llvm_objdump);
    try common.diffFiles(allocator, io, llvm_objdump, local_objdump);
}

fn runEmptyModuleObjectCase(
    allocator: std.mem.Allocator,
    io: std.Io,
    temp: common.TempDir,
    id: []const u8,
    input: []const u8,
) !void {
    const local_asm = try common.allocTempFile(allocator, temp, id, ".s");
    defer allocator.free(local_asm);
    const local_obj = try common.allocTempFile(allocator, temp, id, ".o");
    defer allocator.free(local_obj);
    const readelf_summary = try common.allocTempFile(allocator, temp, id, ".readelf.txt");
    defer allocator.free(readelf_summary);

    const asm_argv = [_][]const u8{ "zig", "build", "run", "--", "--emit=asm", "--target=x86_64-unknown-linux-gnu", input };
    try common.runToFile(allocator, io, &asm_argv, "zig build run", local_asm);
    try expectEmptyFile(allocator, io, local_asm);

    const obj_argv = [_][]const u8{ "zig", "build", "run", "--", "--emit=obj", "--target=x86_64-unknown-linux-gnu", input };
    try common.runToFile(allocator, io, &obj_argv, "zig build run", local_obj);
    const readelf_argv = [_][]const u8{ "readelf", "-h", "-S", "-s", local_obj };
    try common.runToFile(allocator, io, &readelf_argv, "readelf", readelf_summary);
    try expectRegex(allocator, io, readelf_summary, "Type:[[:space:]]+REL");
    try expectRegex(allocator, io, readelf_summary, "Machine:[[:space:]]+Advanced Micro Devices X86-64");
    try expectRegex(allocator, io, readelf_summary, "\\.text");
    try expectRegex(allocator, io, readelf_summary, "\\.symtab");
}

fn runDebugHandoffCase(
    allocator: std.mem.Allocator,
    io: std.Io,
    temp: common.TempDir,
    id: []const u8,
    input: []const u8,
) !void {
    const local_asm = try common.allocTempFile(allocator, temp, id, ".s");
    defer allocator.free(local_asm);
    const local_obj = try common.allocTempFile(allocator, temp, id, ".o");
    defer allocator.free(local_obj);
    const readelf_summary = try common.allocTempFile(allocator, temp, id, ".readelf.txt");
    defer allocator.free(readelf_summary);

    const asm_argv = [_][]const u8{ "zig", "build", "run", "--", "--emit=asm", "--target=x86_64-unknown-linux-gnu", "--input-limit=67108864", input };
    try common.runToFile(allocator, io, &asm_argv, "zig build run", local_asm);
    try expectRegex(allocator, io, local_asm, "^mathtest\\.add:$");
    try expectRegex(allocator, io, local_asm, "[[:space:]]add[[:alpha:]]*[[:space:]]+%esi,[[:space:]]*%eax");
    try expectRegex(allocator, io, local_asm, "[[:space:]]jo[[:space:]]+");
    try expectFixed(allocator, io, local_asm, "callq debug.FullPanic((function 'defaultPanic')).integerOverflow");
    try expectRegex(allocator, io, local_asm, "[[:space:]]retq");

    const obj_argv = [_][]const u8{ "zig", "build", "run", "--", "--emit=obj", "--target=x86_64-unknown-linux-gnu", "--input-limit=67108864", input };
    try common.runToFile(allocator, io, &obj_argv, "zig build run", local_obj);
    const readelf_argv = [_][]const u8{ "readelf", "-W", "-h", "-S", "-s", "-r", local_obj };
    try common.runToFile(allocator, io, &readelf_argv, "readelf", readelf_summary);
    try expectRegex(allocator, io, readelf_summary, "Type:[[:space:]]+REL");
    try expectRegex(allocator, io, readelf_summary, "Machine:[[:space:]]+Advanced Micro Devices X86-64");
    try expectRegex(allocator, io, readelf_summary, "[[:space:]]mathtest\\.add$");
    try expectRegex(allocator, io, readelf_summary, "R_X86_64_PLT32.*debug\\.FullPanic\\(\\(function 'defaultPanic'\\)\\)\\.integerOverflow");
}

fn runAsmCase(allocator: std.mem.Allocator, io: std.Io, temp: common.TempDir, id: []const u8) !void {
    const input = try std.fmt.allocPrint(allocator, "test/codegen/inputs/{s}.ll", .{id});
    defer allocator.free(input);
    const expected = try std.fmt.allocPrint(allocator, "test/codegen/expected/asm/{s}.s", .{id});
    defer allocator.free(expected);
    const actual = try common.allocTempFile(allocator, temp, id, ".s");
    defer allocator.free(actual);

    const argv = [_][]const u8{ "zig", "build", "run", "--", "--emit=asm", "--target=x86_64-unknown-linux-gnu", input };
    try common.runToFile(allocator, io, &argv, "zig build run", actual);
    try common.diffFiles(allocator, io, expected, actual);
}

fn runCodegenSmoke(allocator: std.mem.Allocator, io: std.Io, mode: []const u8) !void {
    const mode_arg = try std.fmt.allocPrint(allocator, "--mode={s}", .{mode});
    defer allocator.free(mode_arg);
    const argv = [_][]const u8{ "zig", "run", "tools/compare_codegen.zig", "--", mode_arg };
    const result = try common.runCapture(allocator, io, &argv, "zig run tools/compare_codegen.zig");
    defer common.freeRunResult(allocator, result);

    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    try stdout_writer.interface.writeAll(result.stdout);
    try stdout_writer.interface.flush();
}

fn expectEmptyFile(allocator: std.mem.Allocator, io: std.Io, path: []const u8) !void {
    const contents = try std.Io.Dir.cwd().readFileAlloc(io, path, allocator, .limited(1024 * 1024));
    defer allocator.free(contents);
    if (contents.len != 0) try common.validationError(io, "expected empty file: {s}\n", .{path});
}

fn expectRegex(allocator: std.mem.Allocator, io: std.Io, path: []const u8, pattern: []const u8) !void {
    const argv = [_][]const u8{ "rg", "-q", pattern, path };
    const result = try common.runCapture(allocator, io, &argv, "rg");
    common.freeRunResult(allocator, result);
}

fn expectFixed(allocator: std.mem.Allocator, io: std.Io, path: []const u8, pattern: []const u8) !void {
    const argv = [_][]const u8{ "rg", "-F", "-q", pattern, path };
    const result = try common.runCapture(allocator, io, &argv, "rg");
    common.freeRunResult(allocator, result);
}
