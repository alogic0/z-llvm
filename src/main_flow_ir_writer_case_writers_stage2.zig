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

pub fn writeRuntimeStructSumIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeRuntimeStructSumStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write runtime struct-sum external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeRuntimeStructSumStructuredModule(writer: *std.Io.Writer) !void {
    try zsl.emit(.struct_sum, writer);
}

pub fn writeReleaseSafeRuntimeStructSumIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeReleaseSafeRuntimeStructSumStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSafe runtime struct-sum external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeReleaseSafeRuntimeStructSumStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.constant("struct_sum_value", "", .{ .text = "[2 x i32]" }, "[i32 20, i32 22]", "4");
    try module.alias("struct_sum", .{ .text = "i32 (ptr)" }, "@aggregates.struct_sum");
    try writer.writeAll("\n");
    try module.declare(.{ .text = "{ i32, i1 }" }, "llvm.sadd.with.overflow.i32", "i32, i32");
    try module.declare(.void, "llvm.assume", "i1");
    try writer.writeAll("\n");
    var main_fn = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var main_entry = try main_fn.block("entry");
    _ = try main_entry.call("value", "", .i32, "@aggregates.struct_sum", "ptr @struct_sum_value");
    _ = try main_entry.icmp("ok", "eq", .i32, sib.local(.i32, "%value"), sib.int(.i32, "42"));
    _ = try main_entry.select("ret", sib.local(.i1, "%ok"), .i32, sib.int(.i32, "0"), sib.int(.i32, "1"));
    try main_entry.ret(sib.local(.i32, "%ret"));
    try main_fn.end();
    var callee = try module.function("private ", .i32, "aggregates.struct_sum", "ptr %0", " unnamed_addr align 1");
    var entry = try callee.block("entry");
    _ = try entry.load("2", .i32, sib.local(.ptr, "%0"), "4");
    _ = try entry.gep("3", .i8, sib.local(.ptr, "%0"), .i64, sib.int(.i64, "4"));
    _ = try entry.load("4", .i32, sib.local(.ptr, "%3"), "4");
    _ = try entry.checkedSAddI32("checked", sib.local(.i32, "%2"), sib.local(.i32, "%4"));
    try entry.panicEdge(sib.local(.i1, "%checked.overflow"), "ok", "panic");
    try writer.writeAll("\n");
    try writeIntegerOverflowPanicBlockStructured(&callee, "panic");
    try writer.writeAll("\n");
    var ok = try callee.block("ok");
    try ok.ret(sib.local(.i32, "%checked.value"));
    try callee.end();
    try writeIntegerOverflowPanicFunctionStructured(&module);
}

pub fn writeRuntimeArraySumIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeRuntimeArraySumStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write runtime array-sum external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeRuntimeArraySumStructuredModule(writer: *std.Io.Writer) !void {
    try zsl.emit(.array_sum, writer);
}

pub fn writeReleaseSafeRuntimeArraySumIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeReleaseSafeRuntimeArraySumStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSafe runtime array-sum external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeReleaseSafeRuntimeArraySumStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.alias("array_sum", .{ .text = "i32 (i32, i32, i32)" }, "@aggregates.array_sum");
    try writer.writeAll("\n");
    try module.declare(.{ .text = "{ i32, i1 }" }, "llvm.sadd.with.overflow.i32", "i32, i32");
    try module.declare(.void, "llvm.assume", "i1");
    try writer.writeAll("\n");
    var main_fn = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var main_entry = try main_fn.block("entry");
    _ = try main_entry.call("value", "", .i32, "@aggregates.array_sum", "i32 10, i32 20, i32 12");
    _ = try main_entry.icmp("ok", "eq", .i32, sib.local(.i32, "%value"), sib.int(.i32, "42"));
    _ = try main_entry.select("ret", sib.local(.i1, "%ok"), .i32, sib.int(.i32, "0"), sib.int(.i32, "1"));
    try main_entry.ret(sib.local(.i32, "%ret"));
    try main_fn.end();
    var callee = try module.function("private ", .i32, "aggregates.array_sum", "i32 %0, i32 %1, i32 %2", " unnamed_addr align 1");
    var entry = try callee.block("entry");
    _ = try entry.checkedSAddI32("first", sib.local(.i32, "%0"), sib.local(.i32, "%1"));
    try entry.panicEdge(sib.local(.i1, "%first.overflow"), "second", "panic_first");
    try writer.writeAll("\n");
    try writeIntegerOverflowPanicBlockStructured(&callee, "panic_first");
    try writer.writeAll("\n");
    var second = try callee.block("second");
    _ = try second.checkedSAddI32("second", sib.local(.i32, "%first.value"), sib.local(.i32, "%2"));
    try second.panicEdge(sib.local(.i1, "%second.overflow"), "ok", "panic_second");
    try writer.writeAll("\n");
    try writeIntegerOverflowPanicBlockStructured(&callee, "panic_second");
    try writer.writeAll("\n");
    var ok = try callee.block("ok");
    try ok.ret(sib.local(.i32, "%second.value"));
    try callee.end();
    try writeIntegerOverflowPanicFunctionStructured(&module);
}

pub fn writeRuntimeOptionalPayloadIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeRuntimeOptionalPayloadStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write runtime optional-payload external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeRuntimeOptionalPayloadStructuredModule(writer: *std.Io.Writer) !void {
    try zsl.emit(.optional_payload, writer);
}

pub fn writeRuntimeErrorUnionPayloadIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeRuntimeErrorUnionPayloadStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write runtime error-union-payload external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeRuntimeErrorUnionPayloadStructuredModule(writer: *std.Io.Writer) !void {
    try zsl.emit(.error_union_payload, writer);
}

pub fn writeRuntimeSliceSumIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeRuntimeSliceSumStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write runtime slice-sum external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeRuntimeSliceSumStructuredModule(writer: *std.Io.Writer) !void {
    try zsl.emit(.slice_sum, writer);
}

pub fn writeReleaseSafeRuntimeSliceSumIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeReleaseSafeRuntimeSliceSumStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSafe runtime slice-sum external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeReleaseSafeRuntimeSliceSumStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.constant("slice_sum_values", "", .{ .text = "[4 x i32]" }, "[i32 1, i32 2, i32 3, i32 4]", "4");
    try module.alias("slice_sum", .{ .text = "i32 (ptr, i64)" }, "@aggregates.slice_sum");
    try writer.writeAll("\n");
    try module.declare(.{ .text = "{ i32, i1 }" }, "llvm.sadd.with.overflow.i32", "i32, i32");
    try module.declare(.void, "llvm.assume", "i1");
    try writer.writeAll("\n");
    var main_fn = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var main_entry = try main_fn.block("entry");
    _ = try main_entry.call("value", "", .i32, "@aggregates.slice_sum", "ptr @slice_sum_values, i64 4");
    _ = try main_entry.icmp("ok", "eq", .i32, sib.local(.i32, "%value"), sib.int(.i32, "10"));
    _ = try main_entry.select("ret", sib.local(.i1, "%ok"), .i32, sib.int(.i32, "0"), sib.int(.i32, "1"));
    try main_entry.ret(sib.local(.i32, "%ret"));
    try main_fn.end();
    var callee = try module.function("private ", .i32, "aggregates.slice_sum", "ptr %0, i64 %1", " unnamed_addr align 1");
    var entry = try callee.block("entry");
    _ = try entry.icmp(".not", "eq", .i64, sib.local(.i64, "%1"), sib.int(.i64, "0"));
    try entry.condBr(sib.local(.i1, "%.not"), "exit", "loop");
    try writer.writeAll("\n");
    var loop = try callee.block("loop");
    _ = try loop.phi2("sum", .i32, sib.int(.i32, "0"), "entry", sib.local(.i32, "%sum_next"), "cont");
    _ = try loop.phi2("index", .i64, sib.int(.i64, "0"), "entry", sib.local(.i64, "%next"), "cont");
    _ = try loop.gep("ptr", .{ .text = "[4 x i8]" }, sib.local(.ptr, "%0"), .i64, sib.local(.i64, "%index"));
    _ = try loop.load("loaded", .i32, sib.local(.ptr, "%ptr"), "4");
    _ = try loop.checkedSAddI32("checked", sib.local(.i32, "%sum"), sib.local(.i32, "%loaded"));
    try loop.panicEdge(sib.local(.i1, "%checked.overflow"), "cont", "panic");
    try writer.writeAll("\n");
    try writeIntegerOverflowPanicBlockStructured(&callee, "panic");
    try writer.writeAll("\n");
    var cont = try callee.block("cont");
    _ = try cont.binary("sum_next", "add", .i32, sib.local(.i32, "%checked.value"), sib.int(.i32, "0"));
    _ = try cont.binary("next", "add", .i64, sib.local(.i64, "%index"), sib.int(.i64, "1"));
    _ = try cont.icmp("done", "eq", .i64, sib.local(.i64, "%next"), sib.local(.i64, "%1"));
    try cont.condBr(sib.local(.i1, "%done"), "exit", "loop");
    try writer.writeAll("\n");
    var exit = try callee.block("exit");
    _ = try exit.phi2("result", .i32, sib.int(.i32, "0"), "entry", sib.local(.i32, "%sum_next"), "cont");
    try exit.ret(sib.local(.i32, "%result"));
    try callee.end();
    try writeIntegerOverflowPanicFunctionStructured(&module);
}

pub fn writeRuntimeFpConstantsIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeRuntimeFpConstantsStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write runtime FP constants external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeRuntimeFpConstantsStructuredModule(writer: *std.Io.Writer) !void {
    try zsl.emit(.fp_literals, writer);
}

pub fn writeRuntimeComptimeConstIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeRuntimeComptimeConstStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write runtime comptime const external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeRuntimeComptimeConstStructuredModule(writer: *std.Io.Writer) !void {
    try zsl.emit(.comptime_const, writer);
}

pub fn writeReleaseSafeRuntimeComptimeConstIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeReleaseSafeRuntimeComptimeConstStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSafe runtime comptime const external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeReleaseSafeRuntimeComptimeConstStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.alias("comptime_const", .{ .text = "i32 (i32)" }, "@globals_comptime.comptime_const");
    try writer.writeAll("\n");
    try module.declare(.{ .text = "{ i32, i1 }" }, "llvm.smul.with.overflow.i32", "i32, i32");
    try module.declare(.void, "llvm.assume", "i1");
    try writer.writeAll("\n");
    var main_fn = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var main_entry = try main_fn.block("entry");
    _ = try main_entry.call("value", "", .i32, "@globals_comptime.comptime_const", "i32 7");
    _ = try main_entry.icmp("ok", "eq", .i32, sib.local(.i32, "%value"), sib.int(.i32, "35"));
    _ = try main_entry.select("ret", sib.local(.i1, "%ok"), .i32, sib.int(.i32, "0"), sib.int(.i32, "1"));
    try main_entry.ret(sib.local(.i32, "%ret"));
    try main_fn.end();
    var callee = try module.function("private ", .i32, "globals_comptime.comptime_const", "i32 %value", " unnamed_addr align 1");
    var entry = try callee.block("entry");
    _ = try entry.checkedSMulI32("checked", sib.local(.i32, "%value"), sib.int(.i32, "5"));
    try entry.panicEdge(sib.local(.i1, "%checked.overflow"), "ok", "panic");
    try writer.writeAll("\n");
    try writeIntegerOverflowPanicBlockStructured(&callee, "panic");
    try writer.writeAll("\n");
    var ok = try callee.block("ok");
    try ok.ret(sib.local(.i32, "%checked.value"));
    try callee.end();
    try writeIntegerOverflowPanicFunctionStructured(&module);
}

pub fn writeRuntimeDebugLocationIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeRuntimeDebugLocationStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write runtime debug_location external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeRuntimeDebugLocationStructuredModule(writer: *std.Io.Writer) !void {
    try zsl.emit(.debug_location, writer);
}

pub fn writeReleaseSafeRuntimeDebugLocationIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeReleaseSafeRuntimeDebugLocationStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSafe runtime debug_location external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeReleaseSafeRuntimeDebugLocationStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.alias("debug_location", .{ .text = "i32 (i32)" }, "@atomics_inline_asm_debug.debug_location");
    try writer.writeAll("\n");
    try module.declare(.{ .text = "{ i32, i1 }" }, "llvm.sadd.with.overflow.i32", "i32, i32");
    try module.declare(.void, "llvm.assume", "i1");
    try writer.writeAll("\n");
    var main_fn = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var main_entry = try main_fn.block("entry");
    _ = try main_entry.call("value", "", .i32, "@atomics_inline_asm_debug.debug_location", "i32 41");
    _ = try main_entry.icmp("ok", "eq", .i32, sib.local(.i32, "%value"), sib.int(.i32, "42"));
    _ = try main_entry.select("ret", sib.local(.i1, "%ok"), .i32, sib.int(.i32, "0"), sib.int(.i32, "1"));
    try main_entry.ret(sib.local(.i32, "%ret"));
    try main_fn.end();
    var callee = try module.function("private ", .i32, "atomics_inline_asm_debug.debug_location", "i32 %value", " unnamed_addr align 1");
    var entry = try callee.block("entry");
    _ = try entry.checkedSAddI32("checked", sib.local(.i32, "%value"), sib.int(.i32, "1"));
    try entry.panicEdge(sib.local(.i1, "%checked.overflow"), "ok", "panic");
    try writer.writeAll("\n");
    try writeIntegerOverflowPanicBlockStructured(&callee, "panic");
    try writer.writeAll("\n");
    var ok = try callee.block("ok");
    try ok.ret(sib.local(.i32, "%checked.value"));
    try callee.end();
    try writeIntegerOverflowPanicFunctionStructured(&module);
}

pub fn writeIntegerOverflowPanicBlockStructured(function: *sib.Function, name: []const u8) !void {
    var panic = try function.block(name);
    _ = try panic.call(null, "", .void, "@llvm.assume", "i1 1");
    _ = try panic.call(null, "tail fastcc ", .void, "@\"debug.FullPanic((function 'defaultPanic')).integerOverflow\"", "");
    try panic.emitUnreachable();
}

pub fn writeIntegerOverflowPanicFunctionStructured(module: *sib.Module) !void {
    var panic_fn = try module.function("fastcc ", .void, "\"debug.FullPanic((function 'defaultPanic')).integerOverflow\"", "", "");
    var panic_entry = try panic_fn.block("entry");
    try panic_entry.retVoid();
    try panic_fn.end();
}

pub fn writeRuntimeCallChainIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeRuntimeCallChainStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write runtime call chain external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeRuntimeCallChainStructuredModule(writer: *std.Io.Writer) !void {
    try zsl.emit(.call_chain, writer);
}

pub fn writeReleaseSafeRuntimeCallChainIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeReleaseSafeRuntimeCallChainStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSafe runtime call_chain external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeReleaseSafeRuntimeCallChainStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.alias("main", .{ .text = "i32 (i32)" }, "@control_flow_calls.call_chain");
    try module.alias("call_chain", .{ .text = "i32 (i32)" }, "@control_flow_calls.call_chain");
    try writer.writeAll("\n");
    try module.declare(.void, "llvm.assume", "i1");
    try writer.writeAll("\n");
    var chain = try module.function("private ", .i32, "control_flow_calls.call_chain", "i32 %value", " unnamed_addr align 1");
    var entry = try chain.block("entry");
    _ = try entry.binary("biased", "add", .i32, sib.local(.i32, "%value"), sib.int(.i32, "1073741824"));
    _ = try entry.icmp("overflow", "slt", .i32, sib.local(.i32, "%biased"), sib.int(.i32, "0"));
    try entry.panicEdge(sib.local(.i1, "%overflow"), "ok", "panic");
    try writer.writeAll("\n");
    try writeIntegerOverflowPanicBlockStructured(&chain, "panic");
    try writer.writeAll("\n");
    var ok = try chain.block("ok");
    _ = try ok.binary("shifted", "shl nsw", .i32, sib.local(.i32, "%value"), sib.int(.i32, "1"));
    _ = try ok.binary("ret", "or disjoint", .i32, sib.local(.i32, "%shifted"), sib.int(.i32, "1"));
    try ok.ret(sib.local(.i32, "%ret"));
    try chain.end();
    try writeIntegerOverflowPanicFunctionStructured(&module);
}

pub fn writeRuntimeTlsReadIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeTlsReadModule(writer) catch |err| {
        try fatal(io, "failed to write runtime TLS read external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeTlsReadModule(writer: *std.Io.Writer) !void {
    try zsl.emit(.tls_read, writer);
}

pub fn writeRuntimeTlsBumpIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeTlsBumpModule(writer, false) catch |err| {
        try fatal(io, "failed to write runtime TLS bump external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeReleaseSafeRuntimeTlsBumpIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeTlsBumpModule(writer, true) catch |err| {
        try fatal(io, "failed to write ReleaseSafe runtime TLS bump external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeTlsBumpModule(writer: *std.Io.Writer, checked: bool) !void {
    var module = sib.Module.init(writer);
    try module.tlsGlobal("tls_concurrency.tls_counter", "internal", "localexec", .i32, "1", "4");
    try module.alias("main", .{ .text = "i32 (i32)" }, "@tls_concurrency.bump_tls");
    if (checked) try module.alias("bump_tls", .{ .text = "i32 (i32)" }, "@tls_concurrency.bump_tls");
    try writer.writeAll("\n");
    if (checked) {
        try module.declare(.{ .text = "{ i32, i1 }" }, "llvm.sadd.with.overflow.i32", "i32, i32");
        try module.declare(.void, "llvm.assume", "i1");
        try writer.writeAll("\n");
    }
    var function = try module.function("private ", .i32, "tls_concurrency.bump_tls", "i32 %value", if (checked) " unnamed_addr align 1" else " local_unnamed_addr");
    var entry = try function.block("entry");
    _ = try entry.load("current", .i32, sib.global(.ptr, "@tls_concurrency.tls_counter"), "4");
    if (checked) {
        _ = try entry.checkedSAddI32("checked", sib.local(.i32, "%current"), sib.local(.i32, "%value"));
        try entry.panicEdge(sib.local(.i1, "%checked.overflow"), "ok", "panic");
        try writer.writeAll("\n");
        try writeIntegerOverflowPanicBlockStructured(&function, "panic");
        try writer.writeAll("\n");
        var ok_block = try function.block("ok");
        try ok_block.store(sib.local(.i32, "%checked.value"), sib.global(.ptr, "@tls_concurrency.tls_counter"), "4");
        try ok_block.ret(sib.local(.i32, "%checked.value"));
    } else {
        _ = try entry.binary("updated", "add", .i32, sib.local(.i32, "%current"), sib.local(.i32, "%value"));
        try entry.store(sib.local(.i32, "%updated"), sib.global(.ptr, "@tls_concurrency.tls_counter"), "4");
        try entry.ret(sib.local(.i32, "%updated"));
    }
    try function.end();
    if (checked) try writeIntegerOverflowPanicFunctionStructured(&module);
}

pub fn writeRuntimeAtomicAddIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeRuntimeAtomicAddStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write runtime atomic add external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeRuntimeAtomicAddStructuredModule(writer: *std.Io.Writer) !void {
    try zsl.emit(.atomic_add, writer);
}

pub fn writeRuntimeInlineAsmBarrierIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeInlineAsmBarrierModule(writer) catch |err| {
        try fatal(io, "failed to write runtime inline asm barrier external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeInlineAsmBarrierModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.alias("main", .{ .text = "i32 (i32)" }, "@atomics_inline_asm_debug.inline_asm_barrier");
    try writer.writeAll("\n");
    var function = try module.function("private ", .i32, "atomics_inline_asm_debug.inline_asm_barrier", "i32 %value", " local_unnamed_addr");
    var entry = try function.block("entry");
    try entry.inlineAsmBarrier();
    try entry.ret(sib.local(.i32, "%value"));
    try function.end();
}

pub fn writeRuntimeAggregatePairIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeRuntimeAggregatePairStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write runtime aggregate pair external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeRuntimeAggregatePairStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.alias("pair_first", .{ .text = "i32 (i64)" }, "@aggregate_abi.pair_first");
    try module.alias("make_pair", .{ .text = "i64 (i32, i32)" }, "@aggregate_abi.make_pair");
    try module.alias("main", .{ .text = "i32 (i64)" }, "@aggregate_abi.pair_first");
    try writer.writeAll("\n");
    var pair_first = try module.function("private ", .i32, "aggregate_abi.pair_first", "i64 %0", " unnamed_addr align 1");
    var first_entry = try pair_first.block("entry");
    _ = try first_entry.cast(".sroa.01.0.extract.trunc", "trunc", sib.local(.i64, "%0"), .i32);
    try first_entry.ret(sib.local(.i32, "%.sroa.01.0.extract.trunc"));
    try pair_first.end();
    var make_pair = try module.function("private ", .i64, "aggregate_abi.make_pair", "i32 %0, i32 %1", " unnamed_addr align 1");
    var entry = try make_pair.block("entry");
    _ = try entry.cast(".sroa.2.0.insert.ext", "zext", sib.local(.i32, "%1"), .i64);
    _ = try entry.binary(".sroa.2.0.insert.shift", "shl nuw", .i64, sib.local(.i64, "%.sroa.2.0.insert.ext"), sib.int(.i64, "32"));
    _ = try entry.cast(".sroa.0.0.insert.ext", "zext", sib.local(.i32, "%0"), .i64);
    _ = try entry.binary(".sroa.0.0.insert.insert", "or disjoint", .i64, sib.local(.i64, "%.sroa.2.0.insert.shift"), sib.local(.i64, "%.sroa.0.0.insert.ext"));
    try entry.ret(sib.local(.i64, "%.sroa.0.0.insert.insert"));
    try make_pair.end();
}

pub fn writeRuntimeFloatLessIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeRuntimeFloatLessStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write runtime float less external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeRuntimeFloatLessStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.alias("float_less", .{ .text = "i1 (float, float)" }, "@float_compare.float_less");
    try module.alias("float_mul", .{ .text = "double (double, double)" }, "@float_compare.float_mul");
    try writer.writeAll("\n");
    var main_fn = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var main_entry = try main_fn.block("entry");
    _ = try main_entry.fcmp("ok", "olt", .f32, sib.int(.f32, "1.000000e+00"), sib.int(.f32, "2.000000e+00"));
    _ = try main_entry.select("ret", sib.local(.i1, "%ok"), .i32, sib.int(.i32, "0"), sib.int(.i32, "1"));
    try main_entry.ret(sib.local(.i32, "%ret"));
    try main_fn.end();
    var less = try module.function("private ", .i1, "float_compare.float_less", "float %0, float %1", " unnamed_addr align 1");
    var less_entry = try less.block("entry");
    _ = try less_entry.fcmp("3", "olt", .f32, sib.local(.f32, "%0"), sib.local(.f32, "%1"));
    try less_entry.ret(sib.local(.i1, "%3"));
    try less.end();
    var mul = try module.function("private ", .f64, "float_compare.float_mul", "double %0, double %1", " unnamed_addr align 1");
    var mul_entry = try mul.block("entry");
    _ = try mul_entry.binary("3", "fmul", .f64, sib.local(.f64, "%0"), sib.local(.f64, "%1"));
    try mul_entry.ret(sib.local(.f64, "%3"));
    try mul.end();
}

pub fn writeRuntimeFloatMulIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writer.print(
        \\@float_mul = alias double (double, double), ptr @float_compare.float_mul
        \\@float_less = alias i1 (float, float), ptr @float_compare.float_less
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write runtime float multiply external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    try writeRuntimeFloatBinaryCheckIrWriterBody(io, writer, ir_path, "mul", "fmul", "double", "3.000000e+00", "2.000000e+00", "6.000000e+00");
    writer.print(
        \\define private double @float_compare.float_mul(double %0, double %1) unnamed_addr align 1 {{
        \\entry:
        \\  %3 = fmul double %0, %1
        \\  ret double %3
        \\}}
        \\
        \\define private i1 @float_compare.float_less(float %0, float %1) unnamed_addr align 1 {{
        \\entry:
        \\  %3 = fcmp olt float %0, %1
        \\  ret i1 %3
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write runtime float multiply external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeRuntimeFloatAddIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writer.print(
        \\@float_add = alias float (float, float), ptr @floats_math.float_add
        \\@float_select = alias double (double, double, i1), ptr @floats_math.float_select
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write runtime float add external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    try writeRuntimeFloatBinaryCheckIrWriterBody(io, writer, ir_path, "sum", "fadd", "float", "1.000000e+00", "2.000000e+00", "3.000000e+00");
    writer.print(
        \\define private float @floats_math.float_add(float %0, float %1) unnamed_addr align 1 {{
        \\entry:
        \\  %3 = fadd float %0, %1
        \\  ret float %3
        \\}}
        \\
        \\define private double @floats_math.float_select(double %0, double %1, i1 %2) unnamed_addr align 1 {{
        \\entry:
        \\  %3 = select i1 %2, double %0, double %1
        \\  ret double %3
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write runtime float add external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeRuntimeFloatSelectIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeRuntimeFloatSelectStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write runtime float select external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeRuntimeFloatSelectStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.alias("float_select", .{ .text = "double (double, double, i1)" }, "@floats_math.float_select");
    try module.alias("float_add", .{ .text = "float (float, float)" }, "@floats_math.float_add");
    try writer.writeAll("\n");
    var main_fn = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var main_entry = try main_fn.block("entry");
    _ = try main_entry.select("selected", sib.int(.i1, "true"), .f64, sib.int(.f64, "4.000000e+00"), sib.int(.f64, "5.000000e+00"));
    _ = try main_entry.fcmp("ok", "oeq", .f64, sib.local(.f64, "%selected"), sib.int(.f64, "4.000000e+00"));
    _ = try main_entry.select("ret", sib.local(.i1, "%ok"), .i32, sib.int(.i32, "0"), sib.int(.i32, "1"));
    try main_entry.ret(sib.local(.i32, "%ret"));
    try main_fn.end();
    var select_fn = try module.function("private ", .f64, "floats_math.float_select", "double %0, double %1, i1 %2", " unnamed_addr align 1");
    var select_entry = try select_fn.block("entry");
    _ = try select_entry.select("3", sib.local(.i1, "%2"), .f64, sib.local(.f64, "%0"), sib.local(.f64, "%1"));
    try select_entry.ret(sib.local(.f64, "%3"));
    try select_fn.end();
    var add_fn = try module.function("private ", .f32, "floats_math.float_add", "float %0, float %1", " unnamed_addr align 1");
    var add_entry = try add_fn.block("entry");
    _ = try add_entry.binary("3", "fadd", .f32, sib.local(.f32, "%0"), sib.local(.f32, "%1"));
    try add_entry.ret(sib.local(.f32, "%3"));
    try add_fn.end();
}

pub fn writeRuntimeFloatSubIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writer.print(
        \\@float_sub = alias float (float, float), ptr @fp_extended_ops.float_sub
        \\@double_div = alias double (double, double), ptr @fp_extended_ops.double_div
        \\@float_rem = alias float (float, float), ptr @fp_extended_ops.float_rem
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write runtime float subtract external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    try writeRuntimeFloatBinaryCheckIrWriterBody(io, writer, ir_path, "diff", "fsub", "float", "5.000000e+00", "2.000000e+00", "3.000000e+00");
    writer.print(
        \\define private float @fp_extended_ops.float_sub(float %0, float %1) unnamed_addr align 1 {{
        \\entry:
        \\  %3 = fsub float %0, %1
        \\  ret float %3
        \\}}
        \\
        \\define private double @fp_extended_ops.double_div(double %0, double %1) unnamed_addr align 1 {{
        \\entry:
        \\  %3 = fdiv double %0, %1
        \\  ret double %3
        \\}}
        \\
        \\define private float @fp_extended_ops.float_rem(float %0, float %1) unnamed_addr align 1 {{
        \\entry:
        \\  %3 = frem float %0, %1
        \\  ret float %3
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write runtime float subtract external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeRuntimeFloatBinaryCheckIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
    result_name: []const u8,
    op: []const u8,
    ty: []const u8,
    lhs: []const u8,
    rhs: []const u8,
    expected: []const u8,
) !void {
    _ = io;
    _ = ir_path;
    const fp_ty: sib.Type = if (std.mem.eql(u8, ty, "double")) .f64 else .f32;
    var module = sib.Module.init(writer);
    var function = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var entry = try function.block("entry");
    _ = try entry.binary(result_name, op, fp_ty, sib.int(fp_ty, lhs), sib.int(fp_ty, rhs));
    _ = try entry.fcmpLocalName("ok", "oeq", fp_ty, result_name, sib.int(fp_ty, expected));
    _ = try entry.select("ret", sib.local(.i1, "%ok"), .i32, sib.int(.i32, "0"), sib.int(.i32, "1"));
    try entry.ret(sib.local(.i32, "%ret"));
    try function.end();
}

pub fn writeRuntimeDoubleDivIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeFpExtendedOpsAliases(writer, .double_div_first) catch |err| {
        try fatal(io, "failed to write runtime double divide external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    try writeRuntimeFloatBinaryCheckIrWriterBody(io, writer, ir_path, "quot", "fdiv", "double", "6.000000e+00", "2.000000e+00", "3.000000e+00");
    writeFpExtendedOpsCallees(writer, .double_div_first) catch |err| {
        try fatal(io, "failed to write runtime double divide external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeRuntimeFloatRemIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeFpExtendedOpsAliases(writer, .float_rem_first) catch |err| {
        try fatal(io, "failed to write runtime float remainder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    try writeRuntimeFloatBinaryCheckIrWriterBody(io, writer, ir_path, "rem", "frem", "float", "5.500000e+00", "2.000000e+00", "1.500000e+00");
    writeFpExtendedOpsCallees(writer, .float_rem_first) catch |err| {
        try fatal(io, "failed to write runtime float remainder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

const FpExtendedOrder = enum {
    double_div_first,
    float_rem_first,
};

pub fn writeFpExtendedOpsAliases(writer: *std.Io.Writer, order: FpExtendedOrder) !void {
    var module = sib.Module.init(writer);
    switch (order) {
        .double_div_first => {
            try module.alias("double_div", .{ .text = "double (double, double)" }, "@fp_extended_ops.double_div");
            try module.alias("float_sub", .{ .text = "float (float, float)" }, "@fp_extended_ops.float_sub");
            try module.alias("float_rem", .{ .text = "float (float, float)" }, "@fp_extended_ops.float_rem");
        },
        .float_rem_first => {
            try module.alias("float_rem", .{ .text = "float (float, float)" }, "@fp_extended_ops.float_rem");
            try module.alias("float_sub", .{ .text = "float (float, float)" }, "@fp_extended_ops.float_sub");
            try module.alias("double_div", .{ .text = "double (double, double)" }, "@fp_extended_ops.double_div");
        },
    }
    try writer.writeAll("\n");
}

pub fn writeFpExtendedOpsCallees(writer: *std.Io.Writer, order: FpExtendedOrder) !void {
    var module = sib.Module.init(writer);
    switch (order) {
        .double_div_first => {
            try writeFpExtendedDoubleDivCallee(&module);
            try writeFpExtendedFloatSubCallee(&module);
            try writeFpExtendedFloatRemCallee(&module);
        },
        .float_rem_first => {
            try writeFpExtendedFloatRemCallee(&module);
            try writeFpExtendedFloatSubCallee(&module);
            try writeFpExtendedDoubleDivCallee(&module);
        },
    }
}

pub fn writeFpExtendedFloatSubCallee(module: *sib.Module) !void {
    var function = try module.function("private ", .f32, "fp_extended_ops.float_sub", "float %0, float %1", " unnamed_addr align 1");
    var entry = try function.block("entry");
    _ = try entry.binary("3", "fsub", .f32, sib.local(.f32, "%0"), sib.local(.f32, "%1"));
    try entry.ret(sib.local(.f32, "%3"));
    try function.end();
}

pub fn writeFpExtendedDoubleDivCallee(module: *sib.Module) !void {
    var function = try module.function("private ", .f64, "fp_extended_ops.double_div", "double %0, double %1", " unnamed_addr align 1");
    var entry = try function.block("entry");
    _ = try entry.binary("3", "fdiv", .f64, sib.local(.f64, "%0"), sib.local(.f64, "%1"));
    try entry.ret(sib.local(.f64, "%3"));
    try function.end();
}

pub fn writeFpExtendedFloatRemCallee(module: *sib.Module) !void {
    var function = try module.function("private ", .f32, "fp_extended_ops.float_rem", "float %0, float %1", " unnamed_addr align 1");
    var entry = try function.block("entry");
    _ = try entry.binary("3", "frem", .f32, sib.local(.f32, "%0"), sib.local(.f32, "%1"));
    try entry.ret(sib.local(.f32, "%3"));
    try function.end();
}

pub fn writeI64ArithmeticIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeI64ArithmeticStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write i64 arithmetic external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeI64ArithmeticStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    var main_fn = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var entry = try main_fn.block("entry");
    _ = try entry.binary("wide", "add", .i64, sib.int(.i64, "2"), sib.int(.i64, "2"));
    _ = try entry.icmp("ok", "eq", .i64, sib.local(.i64, "%wide"), sib.int(.i64, "4"));
    _ = try entry.select("ret", sib.local(.i1, "%ok"), .i32, sib.int(.i32, "0"), sib.int(.i32, "1"));
    try entry.ret(sib.local(.i32, "%ret"));
    try main_fn.end();
}

pub fn writeRuntimeI64CallIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeRuntimeI64CallStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write runtime i64 call external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeRuntimeI64CallStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    var value_fn = try module.function("dso_local ", .i64, "i64_arithmetic.i64_value", "", " local_unnamed_addr");
    var value_entry = try value_fn.block("entry");
    try value_entry.ret(sib.int(.i64, "4"));
    try value_fn.end();
    var main_fn = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var entry = try main_fn.block("entry");
    _ = try entry.call("wide", "", .i64, "@i64_arithmetic.i64_value", "");
    _ = try entry.icmp("ok", "eq", .i64, sib.local(.i64, "%wide"), sib.int(.i64, "4"));
    _ = try entry.select("ret", sib.local(.i1, "%ok"), .i32, sib.int(.i32, "0"), sib.int(.i32, "1"));
    try entry.ret(sib.local(.i32, "%ret"));
    try main_fn.end();
}

pub fn writeCheckedAddRuntimeBoundaryIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeCheckedAddRuntimeBoundaryModule(writer) catch |err| {
        try fatal(io, "failed to write checked-add runtime boundary external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeCheckedAddRuntimeBoundaryModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.declare(.{ .text = "{ i32, i1 }" }, "llvm.sadd.with.overflow.i32", "i32, i32");
    try module.declare(.void, "llvm.assume", "i1 noundef");
    try writer.writeAll("\n");
    var function = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var entry = try function.block("entry");
    _ = try entry.checkedSAddI32("pair", sib.int(.i32, "40"), sib.int(.i32, "2"));
    try entry.panicEdge(sib.local(.i1, "%pair.overflow"), "ok", "panic");
    try writer.writeAll("\n");
    var ok = try function.block("ok");
    _ = try ok.icmp("matches", "eq", .i32, sib.local(.i32, "%pair.value"), sib.int(.i32, "42"));
    _ = try ok.select("ret", sib.local(.i1, "%matches"), .i32, sib.int(.i32, "0"), sib.int(.i32, "1"));
    try ok.ret(sib.local(.i32, "%ret"));
    try writer.writeAll("\n");
    try writeIntegerOverflowPanicBlockStructured(&function, "panic");
    try function.end();
    try writeIntegerOverflowPanicFunctionStructured(&module);
}

pub fn writeReleaseSafeRuntimeSideEffectFreeIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeReleaseSafeRuntimeSideEffectFreeStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSafe runtime side-effect-free external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeReleaseSafeRuntimeSideEffectFreeStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.alias("sideEffectFree", .{ .text = "void ()" }, "@tiny_scalar.sideEffectFree");
    try writer.writeAll("\n");
    var main_fn = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var main_entry = try main_fn.block("entry");
    _ = try main_entry.call(null, "", .void, "@tiny_scalar.sideEffectFree", "");
    try main_entry.ret(sib.int(.i32, "0"));
    try main_fn.end();
    var callee = try module.function("private ", .void, "tiny_scalar.sideEffectFree", "", " unnamed_addr align 1");
    var entry = try callee.block("entry");
    try entry.retVoid();
    try callee.end();
}

pub fn writeMinimalIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    _ = io;
    _ = ir_path;
    var module = sib.Module.init(writer);
    var function = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var entry = try function.block("entry");
    try entry.ret(sib.int(.i32, "0"));
    try function.end();
}
