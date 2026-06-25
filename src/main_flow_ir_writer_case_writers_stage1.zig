const std = @import("std");
const sd = @import("semantic_descriptor.zig");
const sib = @import("structured_ir_builder.zig");
const zsl = @import("zig_semantic_lowering.zig");
const irw = @import("ir_writer_helpers.zig");
const base64_rows = @import("main_base64_rows.zig");

const writeBase64SourceByte = base64_rows.writeBase64SourceByte;
const writeBase64OutputStore = base64_rows.writeBase64OutputStore;
const writeBase64FourByteBundleLoads = base64_rows.writeBase64FourByteBundleLoads;
const base64DecodeTableValue = base64_rows.base64DecodeTableValue;
const writeBase64FullTableConstant = base64_rows.writeBase64FullTableConstant;
const writeBase64FullMainCheck = base64_rows.writeBase64FullMainCheck;
const base64FullTableInitializer = base64_rows.base64FullTableInitializer;
const writeBase64FullStructuredModule = base64_rows.writeBase64FullStructuredModule;
const writeBase64FullMainCheckStructured = base64_rows.writeBase64FullMainCheckStructured;
const writeBase64FullTableLoadStructured = base64_rows.writeBase64FullTableLoadStructured;
const writeBase64OutputStoreStructured = base64_rows.writeBase64OutputStoreStructured;
const writeReleaseSmallRuntimeBase64DecodeBase64FullIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64DecodeBase64FullIrWriterBody;
const writeReleaseSmallRuntimeBase64DecodeBase64FullTextualIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64DecodeBase64FullTextualIrWriterBody;
const writeReleaseSmallRuntimeBase64DecodeStepIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64DecodeStepIrWriterBody;
const writeBase64DecodeStepStructuredModule = base64_rows.writeBase64DecodeStepStructuredModule;
const writeReleaseSmallRuntimeBase64StoreStepIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64StoreStepIrWriterBody;
const writeBase64StoreStepStructuredModule = base64_rows.writeBase64StoreStepStructuredModule;
const writeReleaseSmallRuntimeBase64ResidualByteStepIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64ResidualByteStepIrWriterBody;
const writeBase64ResidualByteStepStructuredModule = base64_rows.writeBase64ResidualByteStepStructuredModule;
const writeReleaseSmallRuntimeBase64PaddingTailStepIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64PaddingTailStepIrWriterBody;
const writeBase64PaddingTailStepStructuredModule = base64_rows.writeBase64PaddingTailStepStructuredModule;
const writeReleaseSmallRuntimeBase64PaddingLoopStepIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64PaddingLoopStepIrWriterBody;
const writeBase64PaddingLoopStepStructuredModule = base64_rows.writeBase64PaddingLoopStepStructuredModule;
const writeReleaseSmallRuntimeBase64PaddingLengthStepIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64PaddingLengthStepIrWriterBody;
const writeBase64PaddingLengthStepStructuredModule = base64_rows.writeBase64PaddingLengthStepStructuredModule;
const writeReleaseSmallRuntimeBase64ChunkGuardStepIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64ChunkGuardStepIrWriterBody;
const writeBase64ChunkGuardStepStructuredModule = base64_rows.writeBase64ChunkGuardStepStructuredModule;
const writeReleaseSmallRuntimeBase64SourceStrideStepIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64SourceStrideStepIrWriterBody;
const writeBase64SourceStrideStructuredModule = base64_rows.writeBase64SourceStrideStructuredModule;
const writeReleaseSmallRuntimeBase64SourceBundleStepIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64SourceBundleStepIrWriterBody;
const writeReleaseSmallRuntimeBase64NextSourceBundleStepIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64NextSourceBundleStepIrWriterBody;
const writeReleaseSmallRuntimeBase64ThirdSourceBundleStepIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64ThirdSourceBundleStepIrWriterBody;
const writeBase64SourceBundleStructuredModule = base64_rows.writeBase64SourceBundleStructuredModule;
const writeBase64FourByteBundleStructured = base64_rows.writeBase64FourByteBundleStructured;
const writeBase64BundleTableLoad = base64_rows.writeBase64BundleTableLoad;
const writeReleaseSmallRuntimeBase64BitBufferStoreStepIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64BitBufferStoreStepIrWriterBody;
const writeBase64BitBufferStoreStructuredModule = base64_rows.writeBase64BitBufferStoreStructuredModule;
const writeReleaseSmallRuntimeBase64LoopAdvanceStepIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64LoopAdvanceStepIrWriterBody;
const writeBase64LoopAdvanceStructuredModule = base64_rows.writeBase64LoopAdvanceStructuredModule;
const writeReleaseSmallRuntimeBase64ResidualGuardStepIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64ResidualGuardStepIrWriterBody;
const writeBase64ResidualGuardStructuredModule = base64_rows.writeBase64ResidualGuardStructuredModule;
const writeReleaseSmallRuntimeBase64ResidualBundleStepIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64ResidualBundleStepIrWriterBody;
const writeReleaseSmallRuntimeBase64ResidualStoreStepIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64ResidualStoreStepIrWriterBody;
const writeBase64ResidualStoreStructuredModule = base64_rows.writeBase64ResidualStoreStructuredModule;
const writeReleaseSmallRuntimeBase64ResidualLengthStepIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64ResidualLengthStepIrWriterBody;
const writeBase64ResidualLengthStructuredModule = base64_rows.writeBase64ResidualLengthStructuredModule;
const writeReleaseSmallRuntimeBase64ResidualTableCheckStepIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64ResidualTableCheckStepIrWriterBody;
const writeBase64ResidualTableCheckStructuredModule = base64_rows.writeBase64ResidualTableCheckStructuredModule;
const writeReleaseSmallRuntimeBase64ResidualAccumulatorStepIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64ResidualAccumulatorStepIrWriterBody;
const writeBase64ResidualAccumulatorStructuredModule = base64_rows.writeBase64ResidualAccumulatorStructuredModule;
const writeReleaseSmallRuntimeBase64ResidualLoopAdvanceStepIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64ResidualLoopAdvanceStepIrWriterBody;
const writeBase64ResidualLoopAdvanceStructuredModule = base64_rows.writeBase64ResidualLoopAdvanceStructuredModule;
const writeReleaseSmallRuntimeBase64ResidualPaddingCheckStepIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64ResidualPaddingCheckStepIrWriterBody;
const writeBase64ResidualPaddingCheckStructuredModule = base64_rows.writeBase64ResidualPaddingCheckStructuredModule;
const writeReleaseSmallRuntimeBase64ResidualFinalMaskStepIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64ResidualFinalMaskStepIrWriterBody;
const writeBase64ResidualFinalMaskStructuredModule = base64_rows.writeBase64ResidualFinalMaskStructuredModule;
const writeReleaseSmallRuntimeBase64ResidualPaddingLoopStepIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64ResidualPaddingLoopStepIrWriterBody;
const writeBase64ResidualPaddingLoopStructuredModule = base64_rows.writeBase64ResidualPaddingLoopStructuredModule;
const writeReleaseSmallRuntimeBase64DecodeExitStepIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64DecodeExitStepIrWriterBody;
const writeBase64DecodeExitStructuredModule = base64_rows.writeBase64DecodeExitStructuredModule;
const writeBase64TableLookupIrWriterBody = base64_rows.writeBase64TableLookupIrWriterBody;
const writeBase64TableLookupStructuredModule = base64_rows.writeBase64TableLookupStructuredModule;
fn fatal(io: std.Io, comptime fmt: []const u8, args: anytype) noreturn {
    var stderr_buffer: [4096]u8 = undefined;
    var stderr_writer = std.Io.File.stderr().writer(io, &stderr_buffer);
    stderr_writer.interface.print(fmt, args) catch {};
    stderr_writer.interface.flush() catch {};
    std.process.exit(2);
}

pub fn writeTinyScalarIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeTinyScalarStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write tiny scalar external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeTinyScalarStructuredModule(writer: *std.Io.Writer) !void {
    try zsl.emit(.tiny_scalar, writer);
}

pub fn writeIntegersIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeIntegersStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write integers external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeIntegersStructuredModule(writer: *std.Io.Writer) !void {
    try zsl.emit(.integer_arithmetic, writer);
}

pub fn writeErrorSwitchIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeErrorSwitchStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write error_switch external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeErrorSwitchStructuredModule(writer: *std.Io.Writer) !void {
    try zsl.emit(.error_switch_select, writer);
}

pub fn writeControlFlowCallsIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeControlFlowCallsStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write control_flow_calls external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeControlFlowCallsStructuredModule(writer: *std.Io.Writer) !void {
    try zsl.emit(.direct_call, writer);
}

pub fn writeGlobalsComptimeIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeGlobalsComptimeStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write globals_comptime external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeGlobalsComptimeStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.global("globals_comptime.writer_counter", "private", .i32, "5", "4");
    try writer.writeAll("\n");
    var read_global = try module.function("dso_local ", .i32, "globals_comptime.read_global", "", " local_unnamed_addr");
    var read_entry = try read_global.block("entry");
    _ = try read_entry.load("value", .i32, sib.global(.ptr, "@globals_comptime.writer_counter"), "4");
    try read_entry.ret(sib.local(.i32, "%value"));
    try read_global.end();
    var main_fn = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var entry = try main_fn.block("entry");
    _ = try entry.call("value", "", .i32, "@globals_comptime.read_global", "");
    try entry.ret(sib.local(.i32, "%value"));
    try main_fn.end();
}

pub fn writeReleaseSafeRuntimeReadGlobalIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeReleaseSafeRuntimeReadGlobalStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSafe runtime read-global external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeReleaseSafeRuntimeReadGlobalStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.global("globals_comptime.global_counter", "private", .i32, "5", "4");
    try module.alias("read_global", .{ .text = "i32 ()" }, "@globals_comptime.read_global");
    try writer.writeAll("\n");
    var main_fn = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var main_entry = try main_fn.block("entry");
    _ = try main_entry.call("value", "", .i32, "@globals_comptime.read_global", "");
    try main_entry.ret(sib.local(.i32, "%value"));
    try main_fn.end();
    var read_global = try module.function("private ", .i32, "globals_comptime.read_global", "", " unnamed_addr align 1");
    var read_entry = try read_global.block("entry");
    _ = try read_entry.load("value", .i32, sib.global(.ptr, "@globals_comptime.global_counter"), "4");
    try read_entry.ret(sib.local(.i32, "%value"));
    try read_global.end();
}

pub fn writeReleaseSmallRuntimeHiddenAccessIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeReleaseSmallHiddenAccessModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime hidden-access external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeReleaseSmallHiddenAccessModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.global("exports.hidden", "private unnamed_addr", .i32, "0", "4");
    try writer.writeAll("\n");
    try module.alias("getHidden", .{ .text = "i32 ()" }, "@exports.getHidden");
    try module.alias("updateHidden", .{ .text = "void (i32)" }, "@exports.updateHidden");
    try writer.writeAll("\n");
    var main_fn = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var main_entry = try main_fn.block("entry");
    _ = try main_entry.call(null, "", .void, "@exports.updateHidden", "i32 7");
    _ = try main_entry.call("value", "", .i32, "@exports.getHidden", "");
    try main_entry.ret(sib.local(.i32, "%value"));
    try main_fn.end();
    var get_hidden = try module.function("private ", .i32, "exports.getHidden", "", " unnamed_addr align 1");
    var get_entry = try get_hidden.block("entry");
    _ = try get_entry.load("value", .i32, sib.global(.ptr, "@exports.hidden"), "4");
    try get_entry.ret(sib.local(.i32, "%value"));
    try get_hidden.end();
    var update_hidden = try module.function("private ", .void, "exports.updateHidden", "i32 %value", " unnamed_addr align 1");
    var update_entry = try update_hidden.block("entry");
    try update_entry.store(sib.local(.i32, "%value"), sib.global(.ptr, "@exports.hidden"), "4");
    try update_entry.retVoid();
    try update_hidden.end();
}

pub fn writeReleaseSmallRuntimeMixCAddZigIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeReleaseSmallMixCAddZigModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime mixed C/Zig add external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeReleaseSmallMixCAddZigModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.tlsGlobal("C_k", "", "localexec", .i32, "2", "4");
    try module.global("main.zig_k", "private unnamed_addr", .i32, "1", "4");
    try writer.writeAll("\n");
    try module.alias("add_zig", .{ .text = "i32 (i32)" }, "@main.add_zig");
    try module.alias("zig_k", .i32, "@main.zig_k");
    try writer.writeAll("\n");
    var main_fn = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var main_entry = try main_fn.block("entry");
    _ = try main_entry.call("value", "", .i32, "@main.add_zig", "i32 4");
    try main_entry.ret(sib.local(.i32, "%value"));
    try main_fn.end();
    var add_zig = try module.function("private ", .i32, "main.add_zig", "i32 %0", " unnamed_addr align 1");
    var entry = try add_zig.block("entry");
    _ = try entry.load("zig", .i32, sib.global(.ptr, "@main.zig_k"), "4");
    _ = try entry.binary("with_arg", "add nsw", .i32, sib.local(.i32, "%zig"), sib.local(.i32, "%0"));
    _ = try entry.load("c", .i32, sib.global(.ptr, "@C_k"), "4");
    _ = try entry.binary("sum", "add nsw", .i32, sib.local(.i32, "%with_arg"), sib.local(.i32, "%c"));
    try entry.ret(sib.local(.i32, "%sum"));
    try add_zig.end();
}

pub fn writeReleaseSmallRuntimeMixCAddMayPanicIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeReleaseSmallMixCAddMayPanicModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime mixed C/Zig panic add external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeReleaseSmallMixCAddMayPanicModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.global("main.zig_k", "private unnamed_addr", .i32, "1", "4");
    try module.constant("__anon_14658", "private unnamed_addr", .{ .text = "[13 x i8]" }, "c\"negative int\\00\"", "1");
    try writer.writeAll("\n");
    try module.alias("add_may_panic", .{ .text = "i32 (i32)" }, "@main.add_may_panic");
    try module.alias("zig_k", .i32, "@main.zig_k");
    try writer.writeAll("\n");
    var main_fn = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var main_entry = try main_fn.block("entry");
    _ = try main_entry.call("value", "", .i32, "@main.add_may_panic", "i32 4");
    try main_entry.ret(sib.local(.i32, "%value"));
    try main_fn.end();
    var add_fn = try module.function("private ", .i32, "main.add_may_panic", "i32 %0", " unnamed_addr align 1");
    var entry = try add_fn.block("entry");
    _ = try entry.icmp("negative", "slt", .i32, sib.local(.i32, "%0"), sib.int(.i32, "0"));
    try entry.condBr(sib.local(.i1, "%negative"), "panic", "ok");
    try writer.writeAll("\n");
    var panic = try add_fn.block("panic");
    _ = try panic.call(null, "", .void, "@llvm.assume", "i1 1");
    _ = try panic.call(null, "tail fastcc ", .void, "@debug.defaultPanic", "ptr @__anon_14658, i64 12");
    try panic.emitUnreachable();
    try writer.writeAll("\n");
    var ok = try add_fn.block("ok");
    _ = try ok.load("base", .i32, sib.global(.ptr, "@main.zig_k"), "4");
    _ = try ok.binary("sum", "add nsw", .i32, sib.local(.i32, "%base"), sib.local(.i32, "%0"));
    try ok.ret(sib.local(.i32, "%sum"));
    try add_fn.end();
    var panic_fn = try module.function("fastcc ", .void, "debug.defaultPanic", "ptr %msg, i64 %len", "");
    var panic_entry = try panic_fn.block("entry");
    try panic_entry.retVoid();
    try panic_fn.end();
}

pub fn writeReleaseSmallRuntimeUmulFixSatI64IrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeReleaseSmallUmulFixSatI64StructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime umul.fix.sat.i64 external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeReleaseSmallUmulFixSatI64StructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.alias("main", .{ .text = "i64 ()" }, "@no_compile_panic_for_unchecked_arith.entry");
    try module.alias("entry", .{ .text = "i64 ()" }, "@no_compile_panic_for_unchecked_arith.entry");
    try writer.writeAll("\n");
    try module.declare(.i64, "llvm.umul.fix.sat.i64", "i64, i64, i32 immarg");
    try writer.writeAll("\n");
    var function = try module.function("private ", .i64, "no_compile_panic_for_unchecked_arith.entry", "", " unnamed_addr align 1");
    var entry = try function.block("entry");
    _ = try entry.call("value", "tail ", .i64, "@llvm.umul.fix.sat.i64", "i64 0, i64 2, i32 0");
    try entry.ret(sib.local(.i64, "%value"));
    try function.end();
}

pub fn writeReleaseSmallRuntimeInheritWantSafetyI64IrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeReleaseSmallInheritWantSafetyI64StructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime inherit-want-safety i64 external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeReleaseSmallInheritWantSafetyI64StructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.alias("main", .{ .text = "i64 ()" }, "@inherit_want_safety.entry");
    try module.alias("entry", .{ .text = "i64 ()" }, "@inherit_want_safety.entry");
    try writer.writeAll("\n");
    var function = try module.function("private ", .i64, "inherit_want_safety.entry", "", " unnamed_addr align 1");
    var entry = try function.block("entry");
    try entry.ret(sib.int(.i64, "4"));
    try function.end();
}

pub fn writeReleaseSmallRuntimeCompileAsmUnreachableIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeReleaseSmallCompileAsmUnreachableStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime compile-asm unreachable external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeReleaseSmallCompileAsmUnreachableStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.alias("compile_asm_main", .{ .text = "void (i32, i32, i32)" }, "@main.main");
    try writer.writeAll("\n");
    var main_fn = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var main_entry = try main_fn.block("entry");
    try main_entry.ret(sib.int(.i32, "0"));
    try main_fn.end();
    var asm_fn = try module.function("private ", .void, "main.main", "i32 %0, i32 %1, i32 %2", " unnamed_addr align 1");
    var asm_entry = try asm_fn.block("entry");
    try asm_entry.emitUnreachable();
    try asm_fn.end();
}

pub fn writeReleaseSmallAddressSpaceStartTrampolineIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeReleaseSmallAddressSpaceStartTrampolineStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall address-space start-trampoline external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeReleaseSmallAddressSpaceStartTrampolineStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.alias("start_trampoline_entry", .{ .text = "void ()" }, "@start._start");
    try module.declare(.void, "start.posixCallMainAndExit", "ptr");
    try writer.writeAll("\n");
    try writeRet0Main(&module);
    var start_fn = try module.function("private ", .void, "start._start", "", " unnamed_addr align 1");
    var entry = try start_fn.block("0");
    try entry.startTrampolineInlineAsm("start._start", "start.posixCallMainAndExit");
    try entry.emitUnreachable();
    try start_fn.end();
    try writeVoidStub(&module, "start.posixCallMainAndExit", "ptr %0");
}

pub fn writeReleaseSmallGetauxvalIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeReleaseSmallGetauxvalStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall getauxval pointer-walk external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeReleaseSmallGetauxvalStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.global("os.linux.elf_aux_maybe", "private unnamed_addr", .ptr, "null", "8");
    try module.alias("getauxval", .{ .text = "i64 (i64)" }, "@os.linux.getauxvalImpl");
    try writer.writeAll("\n");
    try writeRet0Main(&module);
    var function = try module.function("private ", .i64, "os.linux.getauxvalImpl", "i64 %0", " unnamed_addr align 1");
    var entry = try function.block("1");
    _ = try entry.load("2", .ptr, sib.global(.ptr, "@os.linux.elf_aux_maybe"), "8");
    _ = try entry.icmp(".not", "eq", .ptr, sib.local(.ptr, "%2"), sib.Value.constant(.ptr, "null"));
    try entry.condBr(sib.local(.i1, "%.not"), "common.ret", ".preheader");
    try writer.writeAll("\n");
    var common_ret = try function.block("common.ret");
    _ = try common_ret.phi3("common.ret.op", .i64, sib.local(.i64, "%10"), "8", sib.int(.i64, "0"), "1", sib.int(.i64, "0"), ".preheader");
    try common_ret.ret(sib.local(.i64, "%common.ret.op"));
    try writer.writeAll("\n");
    var preheader = try function.block(".preheader");
    _ = try preheader.phi2(".0", .i64, sib.local(.i64, "%7"), "5", sib.int(.i64, "0"), "1");
    _ = try preheader.gep("3", .{ .text = "[16 x i8]" }, sib.local(.ptr, "%2"), .i64, sib.local(.i64, "%.0"));
    _ = try preheader.load("4", .i64, sib.local(.ptr, "%3"), "8");
    _ = try preheader.icmp(".not8", "eq", .i64, sib.local(.i64, "%4"), sib.int(.i64, "0"));
    try preheader.condBr(sib.local(.i1, "%.not8"), "common.ret", "5");
    try writer.writeAll("\n");
    var compare = try function.block("5");
    _ = try compare.icmp("6", "eq", .i64, sib.local(.i64, "%4"), sib.local(.i64, "%0"));
    _ = try compare.binary("7", "add nuw", .i64, sib.local(.i64, "%.0"), sib.int(.i64, "1"));
    try compare.condBr(sib.local(.i1, "%6"), "8", ".preheader");
    try writer.writeAll("\n");
    var found = try function.block("8");
    _ = try found.gep("9", .i8, sib.local(.ptr, "%3"), .i64, sib.int(.i64, "8"));
    _ = try found.load("10", .i64, sib.local(.ptr, "%9"), "8");
    try found.br("common.ret");
    try function.end();
}

pub fn writeReleaseSmallCAbiF128SretIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeReleaseSmallCAbiF128SretStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall f128 sret/byval external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeReleaseSmallCAbiF128SretStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.constant("__anon_762", "private unnamed_addr", .{ .text = "[13 x i8]" }, "c\"test failure\\00\"", "1");
    try module.alias("zig_f128_f128_struct", .{ .text = "void (ptr, ptr)" }, "@main.zig_f128_f128_struct");
    try module.declare(.i32, "__eqtf2", "fp128, fp128");
    try module.declare(.void, "debug.defaultPanic", "ptr, i64");
    try writer.writeAll("\n");
    try writeRet0Main(&module);
    var function = try module.function("private ", .void, "main.zig_f128_f128_struct", "ptr %0, ptr %1", " unnamed_addr align 1");
    var entry = try function.block("2");
    _ = try entry.load(".sroa.0.0.copyload", .fp128, sib.local(.ptr, "%1"), "16");
    _ = try entry.gep(".sroa.2.0..sroa_idx", .i8, sib.local(.ptr, "%1"), .i64, sib.int(.i64, "16"));
    _ = try entry.load(".sroa.2.0.copyload", .fp128, sib.local(.ptr, "%.sroa.2.0..sroa_idx"), "16");
    _ = try entry.call("3", "tail ", .i32, "@__eqtf2", "fp128 %.sroa.0.0.copyload, fp128 0xL00000000000000004002A00000000000");
    _ = try entry.icmp("4", "eq", .i32, sib.local(.i32, "%3"), sib.int(.i32, "0"));
    try entry.condBr(sib.local(.i1, "%4"), "5", "8");
    try writer.writeAll("\n");
    var second = try function.block("5");
    _ = try second.call("6", "tail ", .i32, "@__eqtf2", "fp128 %.sroa.2.0.copyload, fp128 0xL00000000000000004004C80000000000");
    _ = try second.icmp("7", "eq", .i32, sib.local(.i32, "%6"), sib.int(.i32, "0"));
    try second.condBr(sib.local(.i1, "%7"), "9", "11");
    try writer.writeAll("\n");
    var first_panic = try function.block("8");
    _ = try first_panic.call(null, "tail fastcc ", .void, "@debug.defaultPanic", "ptr @__anon_762, i64 12");
    try first_panic.emitUnreachable();
    try writer.writeAll("\n");
    var success = try function.block("9");
    try success.store(sib.Value.constant(.fp128, "0xL00000000000000004003800000000000"), sib.local(.ptr, "%0"), "16");
    _ = try success.gep("10", .i8, sib.local(.ptr, "%0"), .i64, sib.int(.i64, "16"));
    try success.store(sib.Value.constant(.fp128, "0xL00000000000000004005100000000000"), sib.local(.ptr, "%10"), "16");
    try success.retVoid();
    try writer.writeAll("\n");
    var second_panic = try function.block("11");
    _ = try second_panic.call(null, "tail fastcc ", .void, "@debug.defaultPanic", "ptr @__anon_762, i64 12");
    try second_panic.emitUnreachable();
    try function.end();
    try writeEqtf2Stub(&module);
    try writeDefaultPanicStub(&module);
}

pub fn writeReleaseSmallLogicalPtrUnreachableIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeReleaseSmallLogicalPtrUnreachableStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall logical-pointer unreachable external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeReleaseSmallLogicalPtrUnreachableStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.alias("elemVal", .{ .text = "void ()" }, "@illegal_operation_on_logical_ptr.elemVal");
    try module.alias("elemPtr", .{ .text = "void ()" }, "@illegal_operation_on_logical_ptr.elemPtr");
    try writer.writeAll("\n");
    try writeRet0Main(&module);
    var elem_val = try module.function("private ", .void, "illegal_operation_on_logical_ptr.elemVal", "", " unnamed_addr align 1");
    var elem_val_entry = try elem_val.block("0");
    try elem_val_entry.retVoid();
    try elem_val.end();
    var elem_ptr = try module.function("private ", .void, "illegal_operation_on_logical_ptr.elemPtr", "", " unnamed_addr noreturn align 1");
    var elem_ptr_entry = try elem_ptr.block("0");
    try elem_ptr_entry.emitUnreachable();
    try elem_ptr.end();
}

pub fn writeReleaseSmallVramStoreIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeReleaseSmallVramStoreStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall VRAM volatile-store external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeReleaseSmallVramStoreStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.alias("testPackedStuff", .{ .text = "void (ptr, ptr)" }, "@export_keyword.testPackedStuff");
    try module.alias("writeToVRam", .{ .text = "void ()" }, "@export_keyword.writeToVRam");
    try writer.writeAll("\n");
    try writeRet0Main(&module);
    var test_packed = try module.function("private ", .void, "export_keyword.testPackedStuff", "ptr %0, ptr %1", " unnamed_addr align 1");
    var test_entry = try test_packed.block("2");
    try test_entry.retVoid();
    try test_packed.end();
    var vram = try module.function("private ", .void, "export_keyword.writeToVRam", "", " unnamed_addr align 1");
    var entry = try vram.block("0");
    try entry.volatileStore(sib.int(.i8, "88"), sib.Value.pointerIntConstant("inttoptr (i64 536870912 to ptr)"), "536870912");
    try entry.retVoid();
    try vram.end();
}

pub fn writeReleaseSmallSizeofTypeofUnreachableIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeReleaseSmallSizeofTypeofUnreachableStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall sizeof/typeof unreachable external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeReleaseSmallSizeofTypeofUnreachableStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.alias("c_fopen", .{ .text = "ptr (ptr, ptr)" }, "@sizeof_and_typeof.exp.c_fopen");
    try module.alias("c_ftell", .{ .text = "i64 (ptr)" }, "@sizeof_and_typeof.exp.c_ftell");
    try module.alias("c_fputs", .{ .text = "i32 (ptr, ptr)" }, "@sizeof_and_typeof.exp.c_fputs");
    try module.alias("c_printf", .{ .text = "i32 (ptr)" }, "@sizeof_and_typeof.exp.c_printf");
    try writer.writeAll("\n");
    try writeRet0Main(&module);
    try writeUnreachableFunction(&module, .ptr, "sizeof_and_typeof.exp.c_fopen", "ptr %0, ptr %1");
    try writeUnreachableFunction(&module, .i64, "sizeof_and_typeof.exp.c_ftell", "ptr %0");
    try writeUnreachableFunction(&module, .i32, "sizeof_and_typeof.exp.c_fputs", "ptr %0, ptr %1");
    try writeUnreachableFunction(&module, .i32, "sizeof_and_typeof.exp.c_printf", "ptr %0");
}

pub fn writeReleaseSmallRawStartLoopIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeReleaseSmallRawStartLoopStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall raw _start loop external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeReleaseSmallRawStartLoopStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.alias("raw_start_loop_entry", .{ .text = "void ()" }, "@main._start");
    try writer.writeAll("\n");
    try writeRet0Main(&module);
    var start = try module.function("private ", .void, "main._start", "", " unnamed_addr noreturn align 1");
    var entry = try start.block("0");
    try entry.br("1");
    try writer.writeAll("\n");
    var loop = try start.block("1");
    try loop.br("1");
    try start.end();
}

pub fn writeReleaseSmallLibfuzzerFutexWaitIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeReleaseSmallLibfuzzerFutexWaitStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall libfuzzer futex-wait external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeReleaseSmallLibfuzzerFutexWaitStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.alias("runner_futex_wait", .{ .text = "i1 (ptr, i32)" }, "@main.runner_futex_wait");
    try writer.writeAll("\n");
    try writeRet0Main(&module);
    var function = try module.function("private ", .i1, "main.runner_futex_wait", "ptr %0, i32 %1", " unnamed_addr align 1");
    var entry = try function.block("2");
    try entry.ret(sib.int(.i1, "0"));
    try function.end();
}

pub fn writeReleaseSmallLibfuzzerTestNameIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeReleaseSmallLibfuzzerTestNameStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall libfuzzer test-name external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeReleaseSmallLibfuzzerTestNameStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.stringConstant("__anon_16879", "private unnamed_addr", "[5 x i8]", "c\"test\\00\"");
    try module.alias("runner_test_name", .{ .text = "{ i64, i64 } (i32)" }, "@main.runner_test_name");
    try writer.writeAll("\n");
    try writeRet0Main(&module);
    var function = try module.function("private ", .{ .text = "{ i64, i64 }" }, "main.runner_test_name", "i32 %0", " unnamed_addr align 1");
    var entry = try function.block("1");
    try entry.ret(sib.Value.constant(.{ .text = "{ i64, i64 }" }, "{ i64 ptrtoint (ptr @__anon_16879 to i64), i64 4 }"));
    try function.end();
}

pub fn writeReleaseSmallLibfuzzerTestRunIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeReleaseSmallLibfuzzerTestRunStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall libfuzzer test-run external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeReleaseSmallLibfuzzerTestRunStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.stringConstant("__anon_11775", "private unnamed_addr", "[1 x i8]", "zeroinitializer");
    try module.stringConstant("__anon_16031", "private unnamed_addr", "[6 x i8]", "c\"hello\\00\"");
    try module.alias("runner_test_run", .{ .text = "void (i32)" }, "@main.runner_test_run");
    try writer.writeAll("\n");
    try writeRet0Main(&module);
    var runner = try module.function("private ", .void, "main.runner_test_run", "i32 %0", " unnamed_addr align 1");
    var entry = try runner.block("1");
    _ = try entry.call(null, "tail ", .void, "@fuzzer_set_test", "ptr @main.testOne");
    _ = try entry.call(null, "tail ", .void, "@fuzzer_new_input", "i64 ptrtoint (ptr @__anon_11775 to i64), i64 0");
    _ = try entry.call(null, "tail ", .void, "@fuzzer_new_input", "i64 ptrtoint (ptr @__anon_16031 to i64), i64 5");
    _ = try entry.call(null, "tail ", .void, "@fuzzer_start_test", "");
    try entry.retVoid();
    try runner.end();
    try writeVoidStub(&module, "fuzzer_set_test", "ptr %0");
    try writeVoidStub(&module, "fuzzer_new_input", "i64 %0, i64 %1");
    try writeVoidStub(&module, "fuzzer_start_test", "");
    var test_one = try module.function("dso_local ", .i1, "main.testOne", "", " local_unnamed_addr");
    var test_entry = try test_one.block("entry");
    try test_entry.ret(sib.int(.i1, "0"));
    try test_one.end();
}

pub fn writeRet0Main(module: *sib.Module) !void {
    var main_fn = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var entry = try main_fn.block("entry");
    try entry.ret(sib.int(.i32, "0"));
    try main_fn.end();
}

pub fn writeUnreachableFunction(module: *sib.Module, ret_ty: sib.Type, name: []const u8, params: []const u8) !void {
    var function = try module.function("private ", ret_ty, name, params, " unnamed_addr noreturn align 1");
    var entry = try function.block("0");
    try entry.emitUnreachable();
    try function.end();
}

pub fn writeVoidStub(module: *sib.Module, name: []const u8, params: []const u8) !void {
    var function = try module.function("dso_local ", .void, name, params, " local_unnamed_addr");
    var entry = try function.block("entry");
    try entry.retVoid();
    try function.end();
}

pub fn writeEqtf2Stub(module: *sib.Module) !void {
    var function = try module.function("dso_local ", .i32, "__eqtf2", "fp128 %0, fp128 %1", " local_unnamed_addr");
    var entry = try function.block("entry");
    try entry.ret(sib.int(.i32, "0"));
    try function.end();
}

pub fn writeDefaultPanicStub(module: *sib.Module) !void {
    var function = try module.function("fastcc ", .void, "debug.defaultPanic", "ptr %0, i64 %1", "");
    var entry = try function.block("entry");
    try entry.retVoid();
    try function.end();
}

pub fn writeReleaseSmallRuntimeStrFromFloatHelpIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeStrFromFloatHelpStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime strFromFloatHelp external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeStrFromFloatHelpStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.constant("__anon_597", "private unnamed_addr", .{ .text = "%Io.Writer.VTable" }, "{ ptr null, ptr null, ptr null, ptr null }", "8");
    try module.constant("fmt.float.FLOAT64_POW5_INV_SPLIT2", "private unnamed_addr", .{ .text = "[2 x [2 x i64]]" }, "[[2 x i64] [i64 1, i64 2305843009213693952], [2 x i64] [i64 5955668970331000884, i64 1784059615882449851]]", "8");
    try module.constant("fmt.float.FLOAT64_POW5_SPLIT2", "private unnamed_addr", .{ .text = "[2 x [2 x i64]]" }, "[[2 x i64] [i64 0, i64 1152921504606846976], [2 x i64] [i64 0, i64 1490116119384765625]]", "8");
    try module.constant("str.float.copy", "private unnamed_addr", .{ .text = "[6 x i8]" }, "c\"12345\\00\"", "1");
    try module.alias("strFromFloatHelp", .{ .text = "void (double)" }, "@main.strFromFloatHelp");
    try writer.writeAll("\n");
    try module.declare(.void, "llvm.lifetime.start.p0", "ptr");
    try module.declare(.void, "llvm.lifetime.end.p0", "ptr");
    try module.declare(.void, "llvm.assume", "i1");
    try module.declare(.void, "llvm.memcpy.p0.p0.i64", "ptr, ptr, i64, i1");
    try module.declare(.void, "llvm.memset.p0.i64", "ptr, i8, i64, i1");
    try module.declare(.i64, "fmt.float.mulShift64", "i64, ptr, i32");
    try module.declare(.i1, "fmt.float.multipleOfPowerOf5__anon_1356", "i64, i32");
    try module.declare(.i32, "fmt.float.decimalLength__anon_1195", "i64");
    try module.declare(.void, "fmt.float.writeDecimal__anon_1212", "ptr, ptr, i64");
    try writer.writeAll("\n");

    var main_fn = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var main_entry = try main_fn.block("entry");
    _ = try main_entry.call(null, "", .void, "@main.strFromFloatHelp", "double 1.250000e+00");
    _ = try main_entry.call(null, "", .void, "@main.strFromFloatHelp", "double 0.000000e+00");
    try main_entry.ret(sib.int(.i32, "0"));
    try main_fn.end();

    var helper_fn = try module.function("private ", .void, "main.strFromFloatHelp", "double %0", " unnamed_addr align 1");
    var entry = try helper_fn.block("entry");
    _ = try entry.alloca("writer", .{ .text = "%Io.Writer" }, "8");
    _ = try entry.alloca("buffer", .{ .text = "[400 x i8]" }, "1");
    _ = try entry.alloca("tag", .i8, "8");
    _ = try entry.alloca("pow_inv", .v2i64, "16");
    _ = try entry.alloca("pow", .v2i64, "16");
    _ = try entry.alloca("decimal", .i64, "8");
    _ = try entry.alloca("scratch", .{ .text = "[32 x i8]" }, "1");
    _ = try entry.alloca("send_result", .{ .text = "{ i64, i16, [6 x i8] }" }, "8");
    for ([_][]const u8{ "%writer", "%buffer", "%pow_inv", "%pow", "%decimal", "%scratch" }) |slot| {
        try entry.lifetimeStart(sib.local(.ptr, slot));
    }
    try entry.store(sib.global(.ptr, "@__anon_597"), sib.local(.ptr, "%writer"), "8");
    _ = try entry.gep("writer_data", .i8, sib.local(.ptr, "%writer"), .i64, sib.int(.i64, "8"));
    try entry.store(sib.local(.ptr, "%buffer"), sib.local(.ptr, "%writer_data"), "8");
    _ = try entry.gep("writer_len", .i8, sib.local(.ptr, "%writer"), .i64, sib.int(.i64, "16"));
    try entry.store(sib.int(.i64, "400"), sib.local(.ptr, "%writer_len"), "8");
    _ = try entry.gep("writer_pos", .i8, sib.local(.ptr, "%writer"), .i64, sib.int(.i64, "24"));
    try entry.store(sib.int(.i64, "0"), sib.local(.ptr, "%writer_pos"), "8");
    _ = try entry.cast("bits", "bitcast", sib.local(.f64, "%0"), .i64);
    try entry.lifetimeStart(sib.local(.ptr, "%tag"));
    try entry.store(sib.int(.i8, "0"), sib.local(.ptr, "%tag"), "8");
    _ = try entry.binary("mantissa", "and", .i64, sib.local(.i64, "%bits"), sib.int(.i64, "4503599627370495"));
    _ = try entry.binary("expbits", "lshr", .i64, sib.local(.i64, "%bits"), sib.int(.i64, "52"));
    _ = try entry.cast("exp", "trunc", sib.local(.i64, "%expbits"), .i32);
    _ = try entry.binary("masked", "and", .i32, sib.local(.i32, "%exp"), sib.int(.i32, "2047"));
    _ = try entry.icmp("zero_exp", "eq", .i32, sib.local(.i32, "%masked"), sib.int(.i32, "0"));
    _ = try entry.icmp("zero_mantissa", "eq", .i64, sib.local(.i64, "%mantissa"), sib.int(.i64, "0"));
    _ = try entry.binary("is_zero", "and", .i1, sib.local(.i1, "%zero_mantissa"), sib.local(.i1, "%zero_exp"));
    try entry.condBr(sib.local(.i1, "%is_zero"), "done", "check_special");
    try writer.writeAll("\n");

    var check_special = try helper_fn.block("check_special");
    _ = try check_special.icmp("special", "eq", .i32, sib.local(.i32, "%masked"), sib.int(.i32, "2047"));
    try check_special.condBr(sib.local(.i1, "%special"), "special_block", "pow5_inv");
    try writer.writeAll("\n");
    var special_block = try helper_fn.block("special_block");
    try special_block.memset(sib.local(.ptr, "%scratch"), sib.int(.i8, "0"), sib.int(.i64, "32"), sib.int(.i1, "0"));
    try special_block.br("writer_dispatch");
    try writer.writeAll("\n");

    var pow5_inv = try helper_fn.block("pow5_inv");
    _ = try pow5_inv.gep("pow_inv_ptr", .{ .text = "[2 x [2 x i64]]" }, sib.global(.ptr, "@fmt.float.FLOAT64_POW5_INV_SPLIT2"), .i64, sib.int(.i64, "0"));
    _ = try pow5_inv.load("pow_inv_load", .v2i64, sib.local(.ptr, "%pow_inv_ptr"), "8");
    try pow5_inv.store(sib.local(.v2i64, "%pow_inv_load"), sib.local(.ptr, "%pow_inv"), "16");
    _ = try pow5_inv.cast("wide_a", "zext", sib.local(.i64, "%mantissa"), .i128);
    _ = try pow5_inv.cast("wide_b", "zext", sib.int(.i64, "5"), .i128);
    _ = try pow5_inv.binary("wide_mul", "mul", .i128, sib.local(.i128, "%wide_a"), sib.local(.i128, "%wide_b"));
    _ = try pow5_inv.binary("wide_shift", "lshr", .i128, sib.local(.i128, "%wide_mul"), sib.int(.i128, "1"));
    _ = try pow5_inv.cast("wide_trunc", "trunc", sib.local(.i128, "%wide_shift"), .i64);
    _ = try pow5_inv.icmp("assume_ok", "uge", .i64, sib.local(.i64, "%wide_trunc"), sib.int(.i64, "0"));
    _ = try pow5_inv.call(null, "", .void, "@llvm.assume", "i1 %assume_ok");
    _ = try pow5_inv.call("shifted", "fastcc ", .i64, "@fmt.float.mulShift64", "i64 %wide_trunc, ptr %pow_inv, i32 8");
    _ = try pow5_inv.call("multiple", "fastcc ", .i1, "@fmt.float.multipleOfPowerOf5__anon_1356", "i64 %shifted, i32 1");
    try pow5_inv.condBr(sib.local(.i1, "%multiple"), "pow5", "decimal_loop");
    try writer.writeAll("\n");

    var pow5 = try helper_fn.block("pow5");
    _ = try pow5.gep("pow_ptr", .{ .text = "[2 x [2 x i64]]" }, sib.global(.ptr, "@fmt.float.FLOAT64_POW5_SPLIT2"), .i64, sib.int(.i64, "0"));
    _ = try pow5.load("pow_load", .v2i64, sib.local(.ptr, "%pow_ptr"), "8");
    try pow5.store(sib.local(.v2i64, "%pow_load"), sib.local(.ptr, "%pow"), "16");
    _ = try pow5.call("shifted_pow", "fastcc ", .i64, "@fmt.float.mulShift64", "i64 %shifted, ptr %pow, i32 4");
    try pow5.br("decimal_loop");
    try writer.writeAll("\n");

    var decimal_loop = try helper_fn.block("decimal_loop");
    _ = try decimal_loop.phi3("index", .i64, sib.int(.i64, "0"), "pow5_inv", sib.int(.i64, "0"), "pow5", sib.local(.i64, "%next_index"), "decimal_latch");
    _ = try decimal_loop.phi3("value", .i64, sib.local(.i64, "%shifted"), "pow5_inv", sib.local(.i64, "%shifted_pow"), "pow5", sib.local(.i64, "%next_value"), "decimal_latch");
    _ = try decimal_loop.icmp("done_loop", "uge", .i64, sib.local(.i64, "%index"), sib.int(.i64, "3"));
    try decimal_loop.condBr(sib.local(.i1, "%done_loop"), "decimal_write", "decimal_latch");
    try writer.writeAll("\n");
    var decimal_latch = try helper_fn.block("decimal_latch");
    _ = try decimal_latch.binary("digit", "urem", .i64, sib.local(.i64, "%value"), sib.int(.i64, "10"));
    _ = try decimal_latch.cast("digit8", "trunc", sib.local(.i64, "%digit"), .i8);
    _ = try decimal_latch.binary("ascii", "or", .i8, sib.local(.i8, "%digit8"), sib.int(.i8, "48"));
    _ = try decimal_latch.gep("digit_ptr", .{ .text = "[32 x i8]" }, sib.local(.ptr, "%scratch"), .i64, sib.local(.i64, "%index"));
    try decimal_latch.store(sib.local(.i8, "%ascii"), sib.local(.ptr, "%digit_ptr"), "1");
    _ = try decimal_latch.binary("next_value", "udiv", .i64, sib.local(.i64, "%value"), sib.int(.i64, "10"));
    _ = try decimal_latch.binary("next_index", "add", .i64, sib.local(.i64, "%index"), sib.int(.i64, "1"));
    try decimal_latch.br("decimal_loop");
    try writer.writeAll("\n");
    var decimal_write = try helper_fn.block("decimal_write");
    try decimal_write.store(sib.local(.i64, "%value"), sib.local(.ptr, "%decimal"), "8");
    _ = try decimal_write.call("digits", "fastcc ", .i32, "@fmt.float.decimalLength__anon_1195", "i64 %value");
    _ = try decimal_write.cast("digits64", "zext", sib.local(.i32, "%digits"), .i64);
    _ = try decimal_write.call(null, "fastcc ", .void, "@fmt.float.writeDecimal__anon_1212", "ptr %scratch, ptr %decimal, i64 %digits64");
    try decimal_write.memcpy(sib.local(.ptr, "%buffer"), sib.global(.ptr, "@str.float.copy"), sib.int(.i64, "5"), sib.int(.i1, "0"));
    try decimal_write.br("writer_dispatch");
    try writer.writeAll("\n");

    var writer_dispatch = try helper_fn.block("writer_dispatch");
    _ = try writer_dispatch.load("vtable", .ptr, sib.local(.ptr, "%writer"), "8");
    _ = try writer_dispatch.gep("send_slot", .i8, sib.local(.ptr, "%vtable"), .i64, sib.int(.i64, "0"));
    _ = try writer_dispatch.load("send", .ptr, sib.local(.ptr, "%send_slot"), "8");
    _ = try writer_dispatch.call(null, "fastcc ", .void, "%send", "ptr %send_result, ptr %writer, ptr %buffer, i64 1, i64 1");
    try writer_dispatch.br("done");
    try writer.writeAll("\n");

    var done = try helper_fn.block("done");
    for ([_][]const u8{ "%scratch", "%decimal", "%pow", "%pow_inv", "%buffer", "%writer" }) |slot| {
        try done.lifetimeEnd(sib.local(.ptr, slot));
    }
    try done.retVoid();
    try helper_fn.end();
}

pub fn writeStrFromFloatHelpModule(writer: *std.Io.Writer) !void {
    try writer.writeAll(
        \\%Io.Writer.VTable = type { ptr, ptr, ptr, ptr }
        \\%Io.Writer = type { ptr, { ptr, i64 }, i64 }
        \\
    );
    try irw.constant(writer, "__anon_597", "private unnamed_addr", "%Io.Writer.VTable", "{ ptr null, ptr null, ptr null, ptr null }", "8");
    try irw.constant(writer, "fmt.float.FLOAT64_POW5_INV_SPLIT2", "private unnamed_addr", "[2 x [2 x i64]]", "[[2 x i64] [i64 1, i64 2305843009213693952], [2 x i64] [i64 5955668970331000884, i64 1784059615882449851]]", "8");
    try irw.constant(writer, "fmt.float.FLOAT64_POW5_SPLIT2", "private unnamed_addr", "[2 x [2 x i64]]", "[[2 x i64] [i64 0, i64 1152921504606846976], [2 x i64] [i64 0, i64 1490116119384765625]]", "8");
    try irw.constant(writer, "str.float.copy", "private unnamed_addr", "[6 x i8]", "c\"12345\\00\"", "1");
    try irw.alias(writer, "strFromFloatHelp", "void (double)", "main.strFromFloatHelp");
    try writer.writeAll(
        \\
        \\declare void @llvm.lifetime.start.p0(ptr)
        \\declare void @llvm.lifetime.end.p0(ptr)
        \\declare void @llvm.assume(i1)
        \\declare void @llvm.memcpy.p0.p0.i64(ptr, ptr, i64, i1)
        \\declare void @llvm.memset.p0.i64(ptr, i8, i64, i1)
        \\declare fastcc i64 @fmt.float.mulShift64(i64, ptr, i32)
        \\declare fastcc i1 @fmt.float.multipleOfPowerOf5__anon_1356(i64, i32)
        \\declare fastcc i32 @fmt.float.decimalLength__anon_1195(i64)
        \\declare fastcc void @fmt.float.writeDecimal__anon_1212(ptr, ptr, i64)
        \\
    );
    try irw.functionHeader(writer, "dso_local ", "i32", "main", "", " local_unnamed_addr");
    try irw.block(writer, "entry");
    try irw.call(writer, null, "", "void", "@main.strFromFloatHelp", "double 1.250000e+00");
    try irw.call(writer, null, "", "void", "@main.strFromFloatHelp", "double 0.000000e+00");
    try irw.ret(writer, "i32", "0");
    try irw.functionEnd(writer);
    try irw.functionHeader(writer, "private ", "void", "main.strFromFloatHelp", "double %0", " unnamed_addr align 1");
    try irw.block(writer, "entry");
    try writeStrFromFloatStackSetup(writer);
    try writeStrFromFloatClassification(writer);
    try writeStrFromFloatControlFlow(writer);
    try irw.functionEnd(writer);
}

pub fn writeStrFromFloatStackSetup(writer: *std.Io.Writer) !void {
    try irw.alloca(writer, "writer", "%Io.Writer", "8");
    try irw.alloca(writer, "buffer", "[400 x i8]", "1");
    try irw.alloca(writer, "tag", "i8", "8");
    try irw.alloca(writer, "pow_inv", "<2 x i64>", "16");
    try irw.alloca(writer, "pow", "<2 x i64>", "16");
    try irw.alloca(writer, "decimal", "i64", "8");
    try irw.alloca(writer, "scratch", "[32 x i8]", "1");
    try irw.alloca(writer, "send_result", "{ i64, i16, [6 x i8] }", "8");
    for ([_][]const u8{ "%writer", "%buffer", "%pow_inv", "%pow", "%decimal", "%scratch" }) |slot| {
        try irw.lifetimeStart(writer, slot);
    }
    try irw.store(writer, "ptr", "@__anon_597", "%writer", "8");
    try irw.gep(writer, "writer_data", "i8", "%writer", "8");
    try irw.store(writer, "ptr", "%buffer", "%writer_data", "8");
    try irw.gep(writer, "writer_len", "i8", "%writer", "16");
    try irw.store(writer, "i64", "400", "%writer_len", "8");
    try irw.gep(writer, "writer_pos", "i8", "%writer", "24");
    try irw.store(writer, "i64", "0", "%writer_pos", "8");
}

pub fn writeStrFromFloatClassification(writer: *std.Io.Writer) !void {
    try writer.writeAll(
        \\  %bits = bitcast double %0 to i64
        \\
    );
    try irw.lifetimeStart(writer, "%tag");
    try irw.store(writer, "i8", "0", "%tag", "8");
    try writer.writeAll(
        \\  %mantissa = and i64 %bits, 4503599627370495
        \\  %expbits = lshr i64 %bits, 52
        \\  %exp = trunc i64 %expbits to i32
        \\  %masked = and i32 %exp, 2047
        \\  %zero_exp = icmp eq i32 %masked, 0
        \\  %zero_mantissa = icmp eq i64 %mantissa, 0
        \\  %is_zero = and i1 %zero_mantissa, %zero_exp
        \\
    );
    try irw.condBr(writer, "is_zero", "done", "check_special");
    try writer.writeAll("\n");
}

pub fn writeStrFromFloatControlFlow(writer: *std.Io.Writer) !void {
    try irw.block(writer, "check_special");
    try writer.writeAll("  %special = icmp eq i32 %masked, 2047\n");
    try irw.condBr(writer, "special", "special_block", "pow5_inv");
    try writer.writeAll("\n");
    try irw.block(writer, "special_block");
    try irw.memset(writer, "%scratch", "0", "32", "0");
    try irw.br(writer, "writer_dispatch");
    try writer.writeAll("\n");
    try writeStrFromFloatPowBlocks(writer);
    try writeStrFromFloatDecimalLoop(writer);
    try writeStrFromFloatWriterDispatch(writer);
    try writeStrFromFloatDoneBlock(writer);
}

pub fn writeStrFromFloatPowBlocks(writer: *std.Io.Writer) !void {
    try irw.block(writer, "pow5_inv");
    try irw.gep(writer, "pow_inv_ptr", "[2 x [2 x i64]]", "@fmt.float.FLOAT64_POW5_INV_SPLIT2", "0");
    try irw.load(writer, "pow_inv_load", "<2 x i64>", "%pow_inv_ptr", "8");
    try irw.store(writer, "<2 x i64>", "%pow_inv_load", "%pow_inv", "16");
    try writer.writeAll(
        \\  %wide_a = zext i64 %mantissa to i128
        \\  %wide_b = zext i64 5 to i128
        \\  %wide_mul = mul i128 %wide_a, %wide_b
        \\  %wide_shift = lshr i128 %wide_mul, 1
        \\  %wide_trunc = trunc i128 %wide_shift to i64
        \\  %assume_ok = icmp uge i64 %wide_trunc, 0
        \\  call void @llvm.assume(i1 %assume_ok)
        \\  %shifted = call fastcc i64 @fmt.float.mulShift64(i64 %wide_trunc, ptr %pow_inv, i32 8)
        \\  %multiple = call fastcc i1 @fmt.float.multipleOfPowerOf5__anon_1356(i64 %shifted, i32 1)
        \\
    );
    try irw.condBr(writer, "multiple", "pow5", "decimal_loop");
    try writer.writeAll("\n");
    try irw.block(writer, "pow5");
    try irw.gep(writer, "pow_ptr", "[2 x [2 x i64]]", "@fmt.float.FLOAT64_POW5_SPLIT2", "0");
    try irw.load(writer, "pow_load", "<2 x i64>", "%pow_ptr", "8");
    try irw.store(writer, "<2 x i64>", "%pow_load", "%pow", "16");
    try irw.call(writer, "shifted_pow", "", "fastcc i64", "@fmt.float.mulShift64", "i64 %shifted, ptr %pow, i32 4");
    try irw.br(writer, "decimal_loop");
    try writer.writeAll("\n");
}

pub fn writeStrFromFloatDecimalLoop(writer: *std.Io.Writer) !void {
    try irw.block(writer, "decimal_loop");
    try writer.writeAll(
        \\  %index = phi i64 [ 0, %pow5_inv ], [ 0, %pow5 ], [ %next_index, %decimal_latch ]
        \\  %value = phi i64 [ %shifted, %pow5_inv ], [ %shifted_pow, %pow5 ], [ %next_value, %decimal_latch ]
        \\  %done_loop = icmp uge i64 %index, 3
        \\
    );
    try irw.condBr(writer, "done_loop", "decimal_write", "decimal_latch");
    try writer.writeAll("\n");
    try irw.block(writer, "decimal_latch");
    try writer.writeAll(
        \\  %digit = urem i64 %value, 10
        \\  %digit8 = trunc i64 %digit to i8
        \\  %ascii = or i8 %digit8, 48
        \\
    );
    try irw.gep(writer, "digit_ptr", "[32 x i8]", "%scratch", "%index");
    try irw.store(writer, "i8", "%ascii", "%digit_ptr", "1");
    try writer.writeAll(
        \\  %next_value = udiv i64 %value, 10
        \\  %next_index = add i64 %index, 1
        \\
    );
    try irw.br(writer, "decimal_loop");
    try writer.writeAll("\n");
    try irw.block(writer, "decimal_write");
    try irw.store(writer, "i64", "%value", "%decimal", "8");
    try irw.call(writer, "digits", "", "fastcc i32", "@fmt.float.decimalLength__anon_1195", "i64 %value");
    try writer.writeAll("  %digits64 = zext i32 %digits to i64\n");
    try irw.call(writer, null, "", "fastcc void", "@fmt.float.writeDecimal__anon_1212", "ptr %scratch, ptr %decimal, i64 %digits64");
    try irw.memcpy(writer, "%buffer", "@str.float.copy", "5", "0");
    try irw.br(writer, "writer_dispatch");
    try writer.writeAll("\n");
}

pub fn writeStrFromFloatWriterDispatch(writer: *std.Io.Writer) !void {
    try irw.block(writer, "writer_dispatch");
    try irw.load(writer, "vtable", "ptr", "%writer", "8");
    try irw.gep(writer, "send_slot", "i8", "%vtable", "0");
    try irw.load(writer, "send", "ptr", "%send_slot", "8");
    try irw.call(writer, null, "", "fastcc void", "%send", "ptr %send_result, ptr %writer, ptr %buffer, i64 1, i64 1");
    try irw.br(writer, "done");
    try writer.writeAll("\n");
}

pub fn writeStrFromFloatDoneBlock(writer: *std.Io.Writer) !void {
    try irw.block(writer, "done");
    for ([_][]const u8{ "%scratch", "%decimal", "%pow", "%pow_inv", "%buffer", "%writer" }) |slot| {
        try irw.lifetimeEnd(writer, slot);
    }
    try irw.retVoid(writer);
}

pub fn writeRuntimeCondBranchIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeRuntimeCondBranchStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write runtime conditional branch external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeRuntimeCondBranchStructuredModule(writer: *std.Io.Writer) !void {
    try zsl.emit(.cond_branch, writer);
}

pub fn writeRuntimePhiMergeIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    _ = io;
    _ = ir_path;
    try zsl.emit(.phi_merge, writer);
}

pub fn writeRuntimeLoopSumIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    _ = io;
    _ = ir_path;
    try zsl.emit(.loop_sum, writer);
}

pub fn writeReleaseSafeRuntimeLoopSumIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeReleaseSafeRuntimeLoopSumStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSafe runtime loop sum external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeReleaseSafeRuntimeLoopSumStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.alias("main", .{ .text = "i32 (i32)" }, "@control_flow_calls.loop_sum");
    try module.alias("loop_sum", .{ .text = "i32 (i32)" }, "@control_flow_calls.loop_sum");
    try module.declare(.{ .text = "{ i32, i1 }" }, "llvm.sadd.with.overflow.i32", "i32, i32");
    try module.declare(.void, "llvm.assume", "i1");
    try writer.writeAll("\n");

    var function = try module.function("private ", .i32, "control_flow_calls.loop_sum", "i32 %limit", " local_unnamed_addr");
    var entry = try function.block("entry");
    _ = try entry.icmp("is_zero", "eq", .i32, sib.local(.i32, "%limit"), sib.int(.i32, "0"));
    try entry.condBr(sib.local(.i1, "%is_zero"), "exit_zero", "loop");
    try writer.writeAll("\n");

    var loop = try function.block("loop");
    _ = try loop.phi2("index", .i32, sib.int(.i32, "0"), "entry", sib.local(.i32, "%next"), "cont");
    _ = try loop.phi2("sum", .i32, sib.int(.i32, "0"), "entry", sib.local(.i32, "%sum_next"), "cont");
    _ = try loop.icmp("oob", "eq", .i32, sib.local(.i32, "%index"), sib.int(.i32, "-2147483648"));
    try loop.condBr(sib.local(.i1, "%oob"), "panic_oob", "checked_add");
    try writer.writeAll("\n");

    var checked_add = try function.block("checked_add");
    _ = try checked_add.call("checked", "tail ", .{ .text = "{ i32, i1 }" }, "@llvm.sadd.with.overflow.i32", "i32 %sum, i32 %index");
    _ = try checked_add.extractValue("overflow", "{ i32, i1 }", "%checked", 1, .i1);
    try checked_add.panicEdge(sib.local(.i1, "%overflow"), "cont", "panic_overflow");
    try writer.writeAll("\n");

    var panic_oob = try function.block("panic_oob");
    _ = try panic_oob.call(null, "", .void, "@llvm.assume", "i1 1");
    _ = try panic_oob.call(null, "tail fastcc ", .void, "@\"debug.FullPanic((function 'defaultPanic')).integerOutOfBounds\"", "");
    try panic_oob.emitUnreachable();
    try writer.writeAll("\n");

    var panic_overflow = try function.block("panic_overflow");
    _ = try panic_overflow.call(null, "", .void, "@llvm.assume", "i1 1");
    _ = try panic_overflow.call(null, "tail fastcc ", .void, "@\"debug.FullPanic((function 'defaultPanic')).integerOverflow\"", "");
    try panic_overflow.emitUnreachable();
    try writer.writeAll("\n");

    var cont = try function.block("cont");
    _ = try cont.extractValue("sum_next", "{ i32, i1 }", "%checked", 0, .i32);
    _ = try cont.binary("next", "add", .i32, sib.local(.i32, "%index"), sib.int(.i32, "1"));
    _ = try cont.icmp("done", "eq", .i32, sib.local(.i32, "%next"), sib.local(.i32, "%limit"));
    try cont.condBr(sib.local(.i1, "%done"), "exit", "loop");
    try writer.writeAll("\n");

    var exit_zero = try function.block("exit_zero");
    try exit_zero.ret(sib.int(.i32, "0"));
    try writer.writeAll("\n");

    var exit = try function.block("exit");
    try exit.ret(sib.local(.i32, "%sum_next"));
    try function.end();

    var oob = try module.function("fastcc ", .void, "\"debug.FullPanic((function 'defaultPanic')).integerOutOfBounds\"", "", "");
    var oob_entry = try oob.block("entry");
    try oob_entry.retVoid();
    try oob.end();

    var overflow = try module.function("fastcc ", .void, "\"debug.FullPanic((function 'defaultPanic')).integerOverflow\"", "", "");
    var overflow_entry = try overflow.block("entry");
    try overflow_entry.retVoid();
    try overflow.end();
}

pub fn writeRuntimeSwitchIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeRuntimeSwitchStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write runtime switch external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeRuntimeSwitchStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.constant("switch.table.switch_control.dense_switch", "private unnamed_addr", .{ .text = "[3 x i32]" }, "[i32 11, i32 13, i32 17]", "4");
    try module.alias("main", .{ .text = "i32 (i8)" }, "@switch_control.dense_switch");
    try writer.writeAll("\n");
    var function = try module.function("private range(i32 11, 24) ", .i32, "switch_control.dense_switch", "i8 zeroext %0", " unnamed_addr");
    var entry = try function.block("entry");
    _ = try entry.icmp("in_table", "ult", .i8, sib.local(.i8, "%0"), sib.int(.i8, "3"));
    try entry.condBr(sib.local(.i1, "%in_table"), "switch.lookup", "fallback");
    try writer.writeAll("\n");
    var lookup = try function.block("switch.lookup");
    _ = try lookup.cast("index", "zext", sib.local(.i8, "%0"), .i64);
    _ = try lookup.gep("switch.gep", .i32, sib.global(.ptr, "@switch.table.switch_control.dense_switch"), .i64, sib.local(.i64, "%index"));
    _ = try lookup.load("switch.load", .i32, sib.local(.ptr, "%switch.gep"), "4");
    try lookup.br("merge");
    try writer.writeAll("\n");
    var fallback = try function.block("fallback");
    _ = try fallback.binary("range_base", "add", .i8, sib.local(.i8, "%0"), sib.int(.i8, "-3"));
    _ = try fallback.icmp("in_range", "ult", .i8, sib.local(.i8, "%range_base"), sib.int(.i8, "3"));
    _ = try fallback.select("fallback_value", sib.local(.i1, "%in_range"), .i32, sib.int(.i32, "19"), sib.int(.i32, "23"));
    try fallback.br("merge");
    try writer.writeAll("\n");
    var merge = try function.block("merge");
    _ = try merge.phi2("ret", .i32, sib.local(.i32, "%switch.load"), "switch.lookup", sib.local(.i32, "%fallback_value"), "fallback");
    try merge.ret(sib.local(.i32, "%ret"));
    try function.end();
}

pub fn writeReleaseSafeRuntimeBranchMixIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeReleaseSafeRuntimeBranchMixStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSafe runtime branch_mix external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeReleaseSafeRuntimeBranchMixStructuredModule(writer: *std.Io.Writer) !void {
    const checked_pair: sib.Type = .{ .text = "{ i32, i1 }" };
    var module = sib.Module.init(writer);
    try module.alias("branch_mix", .{ .text = "i32 (i32, i32, i1)" }, "@switch_control.branch_mix");
    try writer.writeAll("\n");
    try module.declare(checked_pair, "llvm.sadd.with.overflow.i32", "i32, i32");
    try module.declare(checked_pair, "llvm.ssub.with.overflow.i32", "i32, i32");
    try module.declare(.void, "llvm.assume", "i1");
    try writer.writeAll("\n");
    var main_fn = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var main_entry = try main_fn.block("entry");
    try main_entry.ret(sib.int(.i32, "0"));
    try main_fn.end();
    var branch_mix = try module.function("private ", .i32, "switch_control.branch_mix", "i32 %a, i32 %b, i1 %flag", " unnamed_addr align 1");
    var entry = try branch_mix.block("entry");
    try entry.condBr(sib.local(.i1, "%flag"), "add_path", "sub_path");
    try writer.writeAll("\n");
    var merge = try branch_mix.block("merge");
    _ = try merge.phi2("value", checked_pair, sib.local(checked_pair, "%add_checked"), "add_path", sib.local(checked_pair, "%sub_checked"), "sub_path");
    try writer.writeAll("  %result = extractvalue { i32, i1 } %value, 0\n");
    try merge.ret(sib.local(.i32, "%result"));
    try writer.writeAll("\n");
    var add_path = try branch_mix.block("add_path");
    _ = try add_path.call("add_checked", "tail ", checked_pair, "@llvm.sadd.with.overflow.i32", "i32 %a, i32 %b");
    try writer.writeAll("  %add_overflow = extractvalue { i32, i1 } %add_checked, 1\n");
    try add_path.panicEdge(sib.local(.i1, "%add_overflow"), "merge", "panic_add");
    try writer.writeAll("\n");
    var sub_path = try branch_mix.block("sub_path");
    _ = try sub_path.call("sub_checked", "tail ", checked_pair, "@llvm.ssub.with.overflow.i32", "i32 %a, i32 %b");
    try writer.writeAll("  %sub_overflow = extractvalue { i32, i1 } %sub_checked, 1\n");
    try sub_path.panicEdge(sib.local(.i1, "%sub_overflow"), "merge", "panic_sub");
    try writer.writeAll("\n");
    try irw.integerOverflowPanicBlock(writer, "panic_add");
    try writer.writeAll("\n");
    try irw.integerOverflowPanicBlock(writer, "panic_sub");
    try branch_mix.end();
    var panic_fn = try module.function("fastcc ", .void, "\"debug.FullPanic((function 'defaultPanic')).integerOverflow\"", "", "");
    var panic_entry = try panic_fn.block("entry");
    try panic_entry.retVoid();
    try panic_fn.end();
}

pub fn writeRuntimeGlobalUpdateIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeRuntimeGlobalUpdateStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write runtime global update external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeRuntimeGlobalUpdateStructuredModule(writer: *std.Io.Writer) !void {
    try zsl.emit(.global_update, writer);
}

pub fn writeReleaseSafeRuntimeGlobalUpdateIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeReleaseSafeGlobalUpdateModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSafe runtime global update external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeReleaseSafeGlobalUpdateModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.global("globals_comptime.global_counter", "private", .i32, "3", "4");
    try module.alias("main", .{ .text = "i32 (i32)" }, "@globals_comptime.update_global");
    try writer.writeAll("\n");
    try module.declare(.{ .text = "{ i32, i1 }" }, "llvm.sadd.with.overflow.i32", "i32, i32");
    try module.declare(.void, "llvm.assume", "i1");
    try writer.writeAll("\n");
    var function = try module.function("private ", .i32, "globals_comptime.update_global", "i32 %value", " unnamed_addr align 1");
    var entry = try function.block("entry");
    _ = try entry.load("current", .i32, sib.global(.ptr, "@globals_comptime.global_counter"), "4");
    _ = try entry.checkedSAddI32("checked", sib.local(.i32, "%current"), sib.local(.i32, "%value"));
    try entry.panicEdge(sib.local(.i1, "%checked.overflow"), "ok", "panic");
    try writer.writeAll("\n");
    try writeIntegerOverflowPanicBlockStructured(&function, "panic");
    try writer.writeAll("\n");
    var ok = try function.block("ok");
    try ok.store(sib.local(.i32, "%checked.value"), sib.global(.ptr, "@globals_comptime.global_counter"), "4");
    try ok.ret(sib.local(.i32, "%checked.value"));
    try function.end();
    try writeIntegerOverflowPanicFunctionStructured(&module);
}

pub fn writeRuntimePointerLoadStoreIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeRuntimePointerLoadStoreStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write runtime pointer load/store external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeRuntimePointerLoadStoreStructuredModule(writer: *std.Io.Writer) !void {
    try zsl.emit(.pointer_load_store, writer);
}

pub fn writeReleaseSafeRuntimePointerLoadStoreIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeReleaseSafeRuntimePointerLoadStoreStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSafe runtime pointer load/store external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeReleaseSafeRuntimePointerLoadStoreStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.global("pointers_memory.writer_input", "dso_local", .i32, "41", "4");
    try module.global("pointers_memory.writer_output", "dso_local", .i32, "0", "4");
    try module.alias("load_store", .{ .text = "i32 (ptr, ptr)" }, "@pointers_memory.load_store");
    try writer.writeAll("\n");
    try module.declare(.{ .text = "{ i32, i1 }" }, "llvm.sadd.with.overflow.i32", "i32, i32");
    try module.declare(.void, "llvm.assume", "i1");
    try writer.writeAll("\n");
    var main_fn = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var main_entry = try main_fn.block("entry");
    _ = try main_entry.load("value", .i32, sib.global(.ptr, "@pointers_memory.writer_input"), "4");
    _ = try main_entry.binary("updated", "add", .i32, sib.local(.i32, "%value"), sib.int(.i32, "1"));
    try main_entry.store(sib.local(.i32, "%updated"), sib.global(.ptr, "@pointers_memory.writer_output"), "4");
    _ = try main_entry.load("stored", .i32, sib.global(.ptr, "@pointers_memory.writer_output"), "4");
    _ = try main_entry.icmp("ok", "eq", .i32, sib.local(.i32, "%stored"), sib.int(.i32, "42"));
    _ = try main_entry.select("ret", sib.local(.i1, "%ok"), .i32, sib.int(.i32, "0"), sib.int(.i32, "1"));
    try main_entry.ret(sib.local(.i32, "%ret"));
    try main_fn.end();
    var callee = try module.function("private ", .i32, "pointers_memory.load_store", "ptr %0, ptr %1", " unnamed_addr align 1");
    var entry = try callee.block("entry");
    _ = try entry.load("3", .i32, sib.local(.ptr, "%0"), "4");
    _ = try entry.checkedSAddI32("4", sib.local(.i32, "%3"), sib.int(.i32, "1"));
    try entry.panicEdge(sib.local(.i1, "%4.overflow"), "ok", "panic");
    try writer.writeAll("\n");
    try writeIntegerOverflowPanicBlockStructured(&callee, "panic");
    try writer.writeAll("\n");
    var ok = try callee.block("ok");
    try ok.store(sib.local(.i32, "%4.value"), sib.local(.ptr, "%1"), "4");
    try ok.ret(sib.local(.i32, "%4.value"));
    try callee.end();
    try writeIntegerOverflowPanicFunctionStructured(&module);
}

pub fn writeRuntimeVolatileRoundtripIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeRuntimeVolatileRoundtripStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write runtime volatile roundtrip external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeRuntimeVolatileRoundtripStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.global("pointers_memory.volatile_slot", "dso_local", .i32, "0", "4");
    try module.alias("volatile_roundtrip", .{ .text = "i32 (ptr, i32)" }, "@pointers_memory.volatile_roundtrip");
    try writer.writeAll("\n");
    var main_fn = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var main_entry = try main_fn.block("entry");
    try main_entry.volatileStore(sib.int(.i32, "42"), sib.global(.ptr, "@pointers_memory.volatile_slot"), "4");
    _ = try main_entry.volatileLoad("value", .i32, sib.global(.ptr, "@pointers_memory.volatile_slot"), "4");
    _ = try main_entry.icmp("ok", "eq", .i32, sib.local(.i32, "%value"), sib.int(.i32, "42"));
    _ = try main_entry.select("ret", sib.local(.i1, "%ok"), .i32, sib.int(.i32, "0"), sib.int(.i32, "1"));
    try main_entry.ret(sib.local(.i32, "%ret"));
    try main_fn.end();
    var callee = try module.function("private ", .i32, "pointers_memory.volatile_roundtrip", "ptr %0, i32 %1", " unnamed_addr align 1");
    var entry = try callee.block("entry");
    try entry.volatileStore(sib.local(.i32, "%1"), sib.local(.ptr, "%0"), "4");
    _ = try entry.volatileLoad("3", .i32, sib.local(.ptr, "%0"), "4");
    try entry.ret(sib.local(.i32, "%3"));
    try callee.end();
}

pub fn writeRuntimeOptionalPointerIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeRuntimeOptionalPointerStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write runtime optional pointer external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeRuntimeOptionalPointerStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.global("optional_pointer.writer_value", "dso_local", .i32, "42", "4");
    try module.alias("optional_ptr_value", .{ .text = "i32 (ptr)" }, "@optional_pointer.optional_ptr_value");
    try writer.writeAll("\n");
    var main_fn = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var main_entry = try main_fn.block("entry");
    _ = try main_entry.icmp(".not", "eq", .ptr, sib.global(.ptr, "@optional_pointer.writer_value"), sib.int(.ptr, "null"));
    try main_entry.condBr(sib.local(.i1, "%.not"), "null", "nonnull");
    try writer.writeAll("\n");
    var null_block = try main_fn.block("null");
    try null_block.ret(sib.int(.i32, "1"));
    try writer.writeAll("\n");
    var nonnull_main = try main_fn.block("nonnull");
    _ = try nonnull_main.load("value", .i32, sib.global(.ptr, "@optional_pointer.writer_value"), "4");
    _ = try nonnull_main.icmp("ok", "eq", .i32, sib.local(.i32, "%value"), sib.int(.i32, "42"));
    _ = try nonnull_main.select("ret", sib.local(.i1, "%ok"), .i32, sib.int(.i32, "0"), sib.int(.i32, "1"));
    try nonnull_main.ret(sib.local(.i32, "%ret"));
    try main_fn.end();
    var callee = try module.function("private ", .i32, "optional_pointer.optional_ptr_value", "ptr %0", " unnamed_addr align 1");
    var entry = try callee.block("entry");
    _ = try entry.icmp(".not", "eq", .ptr, sib.local(.ptr, "%0"), sib.int(.ptr, "null"));
    try entry.condBr(sib.local(.i1, "%.not"), "common.ret", "nonnull");
    try writer.writeAll("\n");
    var common_ret = try callee.block("common.ret");
    _ = try common_ret.phi2("common.ret.op", .i32, sib.local(.i32, "%loaded"), "nonnull", sib.int(.i32, "-1"), "entry");
    try common_ret.ret(sib.local(.i32, "%common.ret.op"));
    try writer.writeAll("\n");
    var nonnull = try callee.block("nonnull");
    _ = try nonnull.load("loaded", .i32, sib.local(.ptr, "%0"), "4");
    try nonnull.br("common.ret");
    try callee.end();
}

pub fn writeRuntimePackedReadFlagIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeRuntimePackedReadFlagStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write runtime packed read-flag external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeRuntimePackedReadFlagStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try writePackedBitsAliases(&module, writer, true);
    var main_fn = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var main_entry = try main_fn.block("entry");
    _ = try main_entry.icmp("flag", "slt", .i8, sib.int(.i8, "-128"), sib.int(.i8, "0"));
    _ = try main_entry.select("ret", sib.local(.i1, "%flag"), .i32, sib.int(.i32, "0"), sib.int(.i32, "1"));
    try main_entry.ret(sib.local(.i32, "%ret"));
    try main_fn.end();
    try writePackedBitsCallees(&module, true);
}

pub fn writeRuntimePackedReplaceLowIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeRuntimePackedReplaceLowStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write runtime packed replace-low external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeRuntimePackedReplaceLowStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try writePackedBitsAliases(&module, writer, false);
    var main_fn = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var main_entry = try main_fn.block("entry");
    _ = try main_entry.binary("high", "and", .i8, sib.int(.i8, "-1"), sib.int(.i8, "-8"));
    _ = try main_entry.binary("low", "and", .i8, sib.int(.i8, "5"), sib.int(.i8, "7"));
    _ = try main_entry.binary("packed", "or", .i8, sib.local(.i8, "%low"), sib.local(.i8, "%high"));
    _ = try main_entry.icmp("ok", "eq", .i8, sib.local(.i8, "%packed"), sib.int(.i8, "-3"));
    _ = try main_entry.select("ret", sib.local(.i1, "%ok"), .i32, sib.int(.i32, "0"), sib.int(.i32, "1"));
    try main_entry.ret(sib.local(.i32, "%ret"));
    try main_fn.end();
    try writePackedBitsCallees(&module, false);
}

pub fn writePackedBitsAliases(module: *sib.Module, writer: *std.Io.Writer, read_first: bool) !void {
    if (read_first) {
        try module.alias("read_flag", .{ .text = "i1 (i8)" }, "@packed_bits.read_flag");
        try module.alias("replace_low", .{ .text = "i8 (i8, i8)" }, "@packed_bits.replace_low");
    } else {
        try module.alias("replace_low", .{ .text = "i8 (i8, i8)" }, "@packed_bits.replace_low");
        try module.alias("read_flag", .{ .text = "i1 (i8)" }, "@packed_bits.read_flag");
    }
    try writer.writeAll("\n");
}

pub fn writePackedBitsCallees(module: *sib.Module, replace_first: bool) !void {
    if (replace_first) {
        try writePackedReplaceLowCallee(module);
        try writePackedReadFlagCallee(module);
    } else {
        try writePackedReadFlagCallee(module);
        try writePackedReplaceLowCallee(module);
    }
}

pub fn writePackedReadFlagCallee(module: *sib.Module) !void {
    var callee = try module.function("private ", .i1, "packed_bits.read_flag", "i8 %0", " unnamed_addr align 1");
    var entry = try callee.block("entry");
    _ = try entry.icmp("2", "slt", .i8, sib.local(.i8, "%0"), sib.int(.i8, "0"));
    try entry.ret(sib.local(.i1, "%2"));
    try callee.end();
}

pub fn writePackedReplaceLowCallee(module: *sib.Module) !void {
    var callee = try module.function("private ", .i8, "packed_bits.replace_low", "i8 %0, i8 %1", " unnamed_addr align 1");
    var entry = try callee.block("entry");
