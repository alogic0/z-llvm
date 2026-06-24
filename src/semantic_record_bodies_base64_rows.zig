const std = @import("std");
const irw = @import("ir_writer_helpers.zig");
const sib = @import("structured_ir_builder.zig");

const zsl = struct {
    fn emit(comptime program: anytype, writer: *std.Io.Writer) !void {
        _ = program;
        _ = writer;
        return error.UnusedExternalWriterCompatibilityStub;
    }
};

fn fatal(io: std.Io, comptime fmt: []const u8, args: anytype) anyerror!noreturn {
    _ = io;
    std.debug.print(fmt, args);
    return error.SemanticRecordFatal;
}

fn writeBase64SourceByte(
    writer: *std.Io.Writer,
    ptr_name: []const u8,
    byte_name: []const u8,
    base_ptr: []const u8,
    offset: []const u8,
) !void {
    try irw.gep(writer, ptr_name, "i8", base_ptr, offset);
    try writer.print("  %{s} = load i8, ptr %{s}, align 1\n", .{ byte_name, ptr_name });
}

fn writeBase64OutputStore(writer: *std.Io.Writer, ptr_name: []const u8, output_base: []const u8, offset: []const u8, ty: []const u8, value: []const u8) !void {
    try irw.gep(writer, ptr_name, "i8", output_base, offset);
    try writer.print("  store {s} {s}, ptr %{s}, align 1\n", .{ ty, value, ptr_name });
}

fn writeBase64FourByteBundleLoads(
    writer: *std.Io.Writer,
    input_global: []const u8,
    base_offset: []const u8,
    table0: []const u8,
    table1: []const u8,
    table2: []const u8,
    table3: []const u8,
) !void {
    try writer.writeAll("\n");
    try irw.gep(writer, "src0", "i8", input_global, base_offset);
    try irw.load(writer, "byte0", "i8", "%src0", "1");
    try irw.indexedTableLoadI32(writer, "word0", table0, "byte0");
    try irw.gep(writer, "src1", "i8", "%src0", "1");
    try irw.load(writer, "byte1", "i8", "%src1", "1");
    try irw.indexedTableLoadI32(writer, "word1", table1, "byte1");
    try writer.print("  %merged1 = or i32 %word1.word, %word0.word\n", .{});
    try irw.gep(writer, "src2", "i8", "%src0", "2");
    try irw.load(writer, "byte2", "i8", "%src2", "1");
    try irw.indexedTableLoadI32(writer, "word2", table2, "byte2");
    try writer.print("  %merged2 = or i32 %merged1, %word2.word\n", .{});
    try irw.gep(writer, "src3", "i8", "%src0", "3");
    try irw.load(writer, "byte3", "i8", "%src3", "1");
    try irw.indexedTableLoadI32(writer, "word3", table3, "byte3");
    try writer.print(
        \\  %word = or i32 %merged2, %word3.word
        \\  %valid = icmp ult i32 %word, 16777216
        \\
    , .{});
}

fn base64DecodeTableValue(byte: u8) u8 {
    if (byte >= 'A' and byte <= 'Z') return byte - 'A';
    if (byte >= 'a' and byte <= 'z') return 26 + byte - 'a';
    if (byte >= '0' and byte <= '9') return 52 + byte - '0';
    if (byte == '+') return 62;
    if (byte == '/') return 63;
    return 0xff;
}

fn writeBase64FullTableConstant(writer: *std.Io.Writer) !void {
    const hex = "0123456789ABCDEF";
    try writer.writeAll("@base64.full_table = private unnamed_addr constant [256 x i8] c\"");
    for (0..256) |index| {
        const value = base64DecodeTableValue(@intCast(index));
        try writer.print("\\{c}{c}", .{ hex[value >> 4], hex[value & 0xf] });
    }
    try writer.writeAll("\", align 1\n");
}

fn writeBase64FullMainCheck(
    writer: *std.Io.Writer,
    name: []const u8,
    input_global: []const u8,
    output_len: u8,
    expected_len: i8,
    expected_bytes: []const u8,
) !void {
    try writer.print(
        \\  %decoded.{s} = call i64 @base64.decode_base_64(ptr @{s}, i64 4, ptr @base64.full_output, i64 {d})
        \\  %{s}.len.ok = icmp eq i64 %decoded.{s}, {d}
        \\
    , .{ name, input_global, output_len, name, name, expected_len });
    var previous = try std.fmt.allocPrint(std.heap.page_allocator, "{s}.len.ok", .{name});
    defer std.heap.page_allocator.free(previous);
    for (expected_bytes, 0..) |byte, index| {
        try writer.print(
            \\  %{s}.out{d}.ptr = getelementptr i8, ptr @base64.full_output, i64 {d}
            \\  %{s}.out{d} = load i8, ptr %{s}.out{d}.ptr, align 1
            \\  %{s}.out{d}.ok = icmp eq i8 %{s}.out{d}, {d}
            \\  %{s}.ok{d} = and i1 %{s}, %{s}.out{d}.ok
            \\
        , .{ name, index, index, name, index, name, index, name, index, name, index, byte, name, index, previous, name, index });
        const next = try std.fmt.allocPrint(std.heap.page_allocator, "{s}.ok{d}", .{ name, index });
        std.heap.page_allocator.free(previous);
        previous = next;
    }
    try writer.print("  %{s}.ok = and i1 %{s}, true\n", .{ name, previous });
}

fn base64FullTableInitializer() ![]const u8 {
    const hex = "0123456789ABCDEF";
    var bytes = try std.heap.page_allocator.alloc(u8, 2 + 256 * 3 + 1);
    bytes[0] = 'c';
    bytes[1] = '"';
    var cursor: usize = 2;
    for (0..256) |index| {
        const value = base64DecodeTableValue(@intCast(index));
        bytes[cursor] = '\\';
        bytes[cursor + 1] = hex[value >> 4];
        bytes[cursor + 2] = hex[value & 0xf];
        cursor += 3;
    }
    bytes[cursor] = '"';
    return bytes;
}

pub fn writeBase64FullStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.constant("base64.full_input_man", "", .{ .text = "[4 x i8]" }, "c\"TWFu\"", "1");
    try module.constant("base64.full_input_ma", "", .{ .text = "[4 x i8]" }, "c\"TWE=\"", "1");
    try module.constant("base64.full_input_m", "", .{ .text = "[4 x i8]" }, "c\"TQ==\"", "1");
    try module.constant("base64.full_input_invalid", "", .{ .text = "[4 x i8]" }, "c\"!!!!\"", "1");
    try module.global("base64.full_output", "", .i32, "0", "4");
    try module.constant("base64.full_table", "private unnamed_addr", .{ .text = "[256 x i8]" }, try base64FullTableInitializer(), "1");
    try writer.writeAll("\n");

    var main_fn = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var main_entry = try main_fn.block("entry");
    try writeBase64FullMainCheckStructured(&main_entry, "man", "base64.full_input_man", 3, 3, "Man");
    try writeBase64FullMainCheckStructured(&main_entry, "ma", "base64.full_input_ma", 2, 2, "Ma");
    try writeBase64FullMainCheckStructured(&main_entry, "m", "base64.full_input_m", 1, 1, "M");
    try writeBase64FullMainCheckStructured(&main_entry, "invalid", "base64.full_input_invalid", 3, -1, "");
    _ = try main_entry.binary("ok.man.ma", "and", .i1, sib.local(.i1, "%man.ok"), sib.local(.i1, "%ma.ok"));
    _ = try main_entry.binary("ok.man.ma.m", "and", .i1, sib.local(.i1, "%ok.man.ma"), sib.local(.i1, "%m.ok"));
    _ = try main_entry.binary("ok", "and", .i1, sib.local(.i1, "%ok.man.ma.m"), sib.local(.i1, "%invalid.ok"));
    _ = try main_entry.select("result", sib.local(.i1, "%ok"), .i32, sib.int(.i32, "0"), sib.int(.i32, "1"));
    try main_entry.ret(sib.local(.i32, "%result"));
    try main_fn.end();

    var decode_fn = try module.function("available_externally ", .i64, "base64.decode_base_64", "ptr %source, i64 %source_len, ptr %output, i64 %output_len", " unnamed_addr");
    var entry = try decode_fn.block("entry");
    _ = try entry.icmp("source.len.ok", "eq", .i64, sib.local(.i64, "%source_len"), sib.int(.i64, "4"));
    try entry.condBr(sib.local(.i1, "%source.len.ok"), "check_output", "decode_fail");
    try writer.writeAll("\n");
    var check_output = try decode_fn.block("check_output");
    try check_output.br("decode_loop");
    try writer.writeAll("\n");
    var loop = try decode_fn.block("decode_loop");
    _ = try loop.phi2("source.index", .i64, sib.int(.i64, "0"), "check_output", sib.local(.i64, "%source.next"), "decode_latch");
    _ = try loop.phi2("output.index", .i64, sib.int(.i64, "0"), "check_output", sib.local(.i64, "%output.next"), "decode_latch");
    _ = try loop.gep("src0", .i8, sib.local(.ptr, "%source"), .i64, sib.local(.i64, "%source.index"));
    _ = try loop.load("b0", .i8, sib.local(.ptr, "%src0"), "1");
    try writeBase64FullTableLoadStructured(&loop, "v0", "%b0");
    _ = try loop.binary("src1.index", "add nuw", .i64, sib.local(.i64, "%source.index"), sib.int(.i64, "1"));
    _ = try loop.gep("src1", .i8, sib.local(.ptr, "%source"), .i64, sib.local(.i64, "%src1.index"));
    _ = try loop.load("b1", .i8, sib.local(.ptr, "%src1"), "1");
    try writeBase64FullTableLoadStructured(&loop, "v1", "%b1");
    _ = try loop.binary("src2.index", "add nuw", .i64, sib.local(.i64, "%source.index"), sib.int(.i64, "2"));
    _ = try loop.gep("src2", .i8, sib.local(.ptr, "%source"), .i64, sib.local(.i64, "%src2.index"));
    _ = try loop.load("b2", .i8, sib.local(.ptr, "%src2"), "1");
    try writeBase64FullTableLoadStructured(&loop, "v2", "%b2");
    _ = try loop.binary("src3.index", "add nuw", .i64, sib.local(.i64, "%source.index"), sib.int(.i64, "3"));
    _ = try loop.gep("src3", .i8, sib.local(.ptr, "%source"), .i64, sib.local(.i64, "%src3.index"));
    _ = try loop.load("b3", .i8, sib.local(.ptr, "%src3"), "1");
    try writeBase64FullTableLoadStructured(&loop, "v3", "%b3");
    _ = try loop.icmp("b2.pad", "eq", .i8, sib.local(.i8, "%b2"), sib.int(.i8, "61"));
    _ = try loop.icmp("b3.pad", "eq", .i8, sib.local(.i8, "%b3"), sib.int(.i8, "61"));
    _ = try loop.icmp("v0.valid", "ne", .i8, sib.local(.i8, "%v0.word"), sib.int(.i8, "-1"));
    _ = try loop.icmp("v1.valid", "ne", .i8, sib.local(.i8, "%v1.word"), sib.int(.i8, "-1"));
    _ = try loop.icmp("v2.valid.raw", "ne", .i8, sib.local(.i8, "%v2.word"), sib.int(.i8, "-1"));
    _ = try loop.select("v2.valid", sib.local(.i1, "%b2.pad"), .i1, sib.int(.i1, "1"), sib.local(.i1, "%v2.valid.raw"));
    _ = try loop.icmp("v3.valid.raw", "ne", .i8, sib.local(.i8, "%v3.word"), sib.int(.i8, "-1"));
    _ = try loop.select("v3.valid", sib.local(.i1, "%b3.pad"), .i1, sib.int(.i1, "1"), sib.local(.i1, "%v3.valid.raw"));
    _ = try loop.select("pad.valid", sib.local(.i1, "%b2.pad"), .i1, sib.local(.i1, "%b3.pad"), sib.int(.i1, "1"));
    _ = try loop.binary("valid01", "and", .i1, sib.local(.i1, "%v0.valid"), sib.local(.i1, "%v1.valid"));
    _ = try loop.binary("valid012", "and", .i1, sib.local(.i1, "%valid01"), sib.local(.i1, "%v2.valid"));
    _ = try loop.binary("valid0123", "and", .i1, sib.local(.i1, "%valid012"), sib.local(.i1, "%v3.valid"));
    _ = try loop.binary("valid", "and", .i1, sib.local(.i1, "%valid0123"), sib.local(.i1, "%pad.valid"));
    _ = try loop.select("output.required.23", sib.local(.i1, "%b3.pad"), .i64, sib.int(.i64, "2"), sib.int(.i64, "3"));
    _ = try loop.select("output.required", sib.local(.i1, "%b2.pad"), .i64, sib.int(.i64, "1"), sib.local(.i64, "%output.required.23"));
    _ = try loop.icmp("output.len.ok", "uge", .i64, sib.local(.i64, "%output_len"), sib.local(.i64, "%output.required"));
    _ = try loop.binary("valid.output", "and", .i1, sib.local(.i1, "%valid"), sib.local(.i1, "%output.len.ok"));
    try loop.condBr(sib.local(.i1, "%valid.output"), "decode_values", "decode_fail");
    try writer.writeAll("\n");
    var values = try decode_fn.block("decode_values");
    _ = try values.binary("v0.masked", "and", .i8, sib.local(.i8, "%v0.word"), sib.int(.i8, "63"));
    _ = try values.binary("v1.masked", "and", .i8, sib.local(.i8, "%v1.word"), sib.int(.i8, "63"));
    _ = try values.binary("v2.masked", "and", .i8, sib.local(.i8, "%v2.word"), sib.int(.i8, "63"));
    _ = try values.binary("v3.masked", "and", .i8, sib.local(.i8, "%v3.word"), sib.int(.i8, "63"));
    _ = try values.select("v2.value", sib.local(.i1, "%b2.pad"), .i8, sib.int(.i8, "0"), sib.local(.i8, "%v2.masked"));
    _ = try values.select("v3.value", sib.local(.i1, "%b3.pad"), .i8, sib.int(.i8, "0"), sib.local(.i8, "%v3.masked"));
    _ = try values.cast("v0.i32", "zext", sib.local(.i8, "%v0.masked"), .i32);
    _ = try values.cast("v1.i32", "zext", sib.local(.i8, "%v1.masked"), .i32);
    _ = try values.cast("v2.i32", "zext", sib.local(.i8, "%v2.value"), .i32);
    _ = try values.cast("v3.i32", "zext", sib.local(.i8, "%v3.value"), .i32);
    _ = try values.binary("shift0", "shl", .i32, sib.local(.i32, "%v0.i32"), sib.int(.i32, "18"));
    _ = try values.binary("shift1", "shl", .i32, sib.local(.i32, "%v1.i32"), sib.int(.i32, "12"));
    _ = try values.binary("word1", "or", .i32, sib.local(.i32, "%shift0"), sib.local(.i32, "%shift1"));
    _ = try values.binary("shift2", "shl", .i32, sib.local(.i32, "%v2.i32"), sib.int(.i32, "6"));
    _ = try values.binary("word2", "or", .i32, sib.local(.i32, "%word1"), sib.local(.i32, "%shift2"));
    _ = try values.binary("word", "or", .i32, sib.local(.i32, "%word2"), sib.local(.i32, "%v3.i32"));
    _ = try values.binary("byte0.shift", "lshr", .i32, sib.local(.i32, "%word"), sib.int(.i32, "16"));
    _ = try values.cast("byte0", "trunc", sib.local(.i32, "%byte0.shift"), .i8);
    try writeBase64OutputStoreStructured(&values, "dst0", "%output", "%output.index", .i8, "%byte0");
    _ = try values.binary("output.next", "add", .i64, sib.local(.i64, "%output.index"), sib.local(.i64, "%output.required"));
    try values.condBr(sib.local(.i1, "%b2.pad"), "decode_done", "store_byte1");
    try writer.writeAll("\n");
    var store1 = try decode_fn.block("store_byte1");
    _ = try store1.binary("dst1.index", "add nuw", .i64, sib.local(.i64, "%output.index"), sib.int(.i64, "1"));
    _ = try store1.binary("byte1.shift", "lshr", .i32, sib.local(.i32, "%word"), sib.int(.i32, "8"));
    _ = try store1.cast("byte1", "trunc", sib.local(.i32, "%byte1.shift"), .i8);
    try writeBase64OutputStoreStructured(&store1, "dst1", "%output", "%dst1.index", .i8, "%byte1");
    try store1.condBr(sib.local(.i1, "%b3.pad"), "decode_done", "store_byte2");
    try writer.writeAll("\n");
    var store2 = try decode_fn.block("store_byte2");
    _ = try store2.binary("dst2.index", "add nuw", .i64, sib.local(.i64, "%output.index"), sib.int(.i64, "2"));
    _ = try store2.cast("byte2", "trunc", sib.local(.i32, "%word"), .i8);
    try writeBase64OutputStoreStructured(&store2, "dst2", "%output", "%dst2.index", .i8, "%byte2");
    _ = try store2.binary("source.next", "add nuw", .i64, sib.local(.i64, "%source.index"), sib.int(.i64, "4"));
    _ = try store2.icmp("done", "eq", .i64, sib.local(.i64, "%source.next"), sib.local(.i64, "%source_len"));
    try store2.condBr(sib.local(.i1, "%done"), "decode_done", "decode_latch");
    try writer.writeAll("\n");
    var latch = try decode_fn.block("decode_latch");
    try latch.br("decode_loop");
    try writer.writeAll("\n");
    var done = try decode_fn.block("decode_done");
    try done.ret(sib.local(.i64, "%output.next"));
    try writer.writeAll("\n");
    var fail = try decode_fn.block("decode_fail");
    try fail.ret(sib.int(.i64, "-1"));
    try decode_fn.end();
}

fn writeBase64FullMainCheckStructured(
    entry: *sib.Block,
    name: []const u8,
    input_global: []const u8,
    output_len: u8,
    expected_len: i8,
    expected_bytes: []const u8,
) !void {
    const decoded = try std.fmt.allocPrint(std.heap.page_allocator, "decoded.{s}", .{name});
    const len_ok = try std.fmt.allocPrint(std.heap.page_allocator, "{s}.len.ok", .{name});
    const input_ref = try std.fmt.allocPrint(std.heap.page_allocator, "@{s}", .{input_global});
    const args = try std.fmt.allocPrint(std.heap.page_allocator, "ptr {s}, i64 4, ptr @base64.full_output, i64 {d}", .{ input_ref, output_len });
    _ = try entry.call(decoded, "", .i64, "@base64.decode_base_64", args);
    const decoded_ref = try std.fmt.allocPrint(std.heap.page_allocator, "%{s}", .{decoded});
    _ = try entry.icmp(len_ok, "eq", .i64, sib.local(.i64, decoded_ref), sib.int(.i64, try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{expected_len})));
    var previous = len_ok;
    for (expected_bytes, 0..) |byte, index| {
        const ptr_name = try std.fmt.allocPrint(std.heap.page_allocator, "{s}.out{d}.ptr", .{ name, index });
        const load_name = try std.fmt.allocPrint(std.heap.page_allocator, "{s}.out{d}", .{ name, index });
        const ok_name = try std.fmt.allocPrint(std.heap.page_allocator, "{s}.out{d}.ok", .{ name, index });
        _ = try entry.gep(ptr_name, .i8, sib.global(.ptr, "@base64.full_output"), .i64, sib.int(.i64, try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{index})));
        const ptr_ref = try std.fmt.allocPrint(std.heap.page_allocator, "%{s}", .{ptr_name});
        _ = try entry.load(load_name, .i8, sib.local(.ptr, ptr_ref), "1");
        const load_ref = try std.fmt.allocPrint(std.heap.page_allocator, "%{s}", .{load_name});
        _ = try entry.icmp(ok_name, "eq", .i8, sib.local(.i8, load_ref), sib.int(.i8, try std.fmt.allocPrint(std.heap.page_allocator, "{d}", .{byte})));
        const next = try std.fmt.allocPrint(std.heap.page_allocator, "{s}.ok{d}", .{ name, index });
        const previous_ref = try std.fmt.allocPrint(std.heap.page_allocator, "%{s}", .{previous});
        const ok_ref = try std.fmt.allocPrint(std.heap.page_allocator, "%{s}", .{ok_name});
        _ = try entry.binary(next, "and", .i1, sib.local(.i1, previous_ref), sib.local(.i1, ok_ref));
        previous = next;
    }
    const final_name = try std.fmt.allocPrint(std.heap.page_allocator, "{s}.ok", .{name});
    const previous_ref = try std.fmt.allocPrint(std.heap.page_allocator, "%{s}", .{previous});
    _ = try entry.binary(final_name, "and", .i1, sib.local(.i1, previous_ref), sib.int(.i1, "1"));
}

fn writeBase64FullTableLoadStructured(entry: *sib.Block, prefix: []const u8, byte_ref: []const u8) !void {
    const idx = try std.fmt.allocPrint(std.heap.page_allocator, "{s}.idx", .{prefix});
    const entry_name = try std.fmt.allocPrint(std.heap.page_allocator, "{s}.entry", .{prefix});
    const word = try std.fmt.allocPrint(std.heap.page_allocator, "{s}.word", .{prefix});
    _ = try entry.cast(idx, "zext", sib.local(.i8, byte_ref), .i64);
    const idx_ref = try std.fmt.allocPrint(std.heap.page_allocator, "%{s}", .{idx});
    _ = try entry.gep2(entry_name, .{ .text = "[256 x i8]" }, sib.global(.ptr, "@base64.full_table"), sib.int(.i64, "0"), sib.local(.i64, idx_ref));
    const entry_ref = try std.fmt.allocPrint(std.heap.page_allocator, "%{s}", .{entry_name});
    _ = try entry.load(word, .i8, sib.local(.ptr, entry_ref), "1");
}

fn writeBase64OutputStoreStructured(entry: *sib.Block, ptr_name: []const u8, output_base: []const u8, offset: []const u8, ty: sib.Type, value: []const u8) !void {
    _ = try entry.gep(ptr_name, .i8, sib.local(.ptr, output_base), .i64, sib.local(.i64, offset));
    const ptr_ref = try std.fmt.allocPrint(std.heap.page_allocator, "%{s}", .{ptr_name});
    try entry.store(sib.local(ty, value), sib.local(.ptr, ptr_ref), "1");
}

pub fn writeReleaseSmallRuntimeBase64DecodeBase64FullIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeBase64FullStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 full decoder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeReleaseSmallRuntimeBase64DecodeBase64FullTextualIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writer.print(
        \\@base64.full_input_man = constant [4 x i8] c"TWFu", align 1
        \\@base64.full_input_ma = constant [4 x i8] c"TWE=", align 1
        \\@base64.full_input_m = constant [4 x i8] c"TQ==", align 1
        \\@base64.full_input_invalid = constant [4 x i8] c"!!!!", align 1
        \\@base64.full_output = global i32 0, align 4
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 full decoder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    writeBase64FullTableConstant(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 full decoder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    writer.print(
        \\
        \\define dso_local i32 @main() local_unnamed_addr {{
        \\entry:
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 full decoder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    writeBase64FullMainCheck(writer, "man", "base64.full_input_man", 3, 3, "Man") catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 full decoder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    writeBase64FullMainCheck(writer, "ma", "base64.full_input_ma", 2, 2, "Ma") catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 full decoder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    writeBase64FullMainCheck(writer, "m", "base64.full_input_m", 1, 1, "M") catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 full decoder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    writeBase64FullMainCheck(writer, "invalid", "base64.full_input_invalid", 3, -1, "") catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 full decoder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    writer.print(
        \\  %ok.man.ma = and i1 %man.ok, %ma.ok
        \\  %ok.man.ma.m = and i1 %ok.man.ma, %m.ok
        \\  %ok = and i1 %ok.man.ma.m, %invalid.ok
        \\  %result = select i1 %ok, i32 0, i32 1
        \\  ret i32 %result
        \\}}
        \\
        \\define available_externally i64 @base64.decode_base_64(ptr %source, i64 %source_len, ptr %output, i64 %output_len) unnamed_addr {{
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 full decoder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    irw.block(writer, "entry") catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 full decoder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    writer.print(
        \\  %source.len.ok = icmp eq i64 %source_len, 4
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 full decoder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    irw.condBr(writer, "source.len.ok", "check_output", "decode_fail") catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 full decoder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    irw.block(writer, "check_output") catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 full decoder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    irw.br(writer, "decode_loop") catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 full decoder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    irw.block(writer, "decode_loop") catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 full decoder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    try irw.phi2(writer, "source.index", "i64", "0", "check_output", "%source.next", "decode_latch");
    try irw.phi2(writer, "output.index", "i64", "0", "check_output", "%output.next", "decode_latch");
    irw.gep(writer, "src0", "i8", "%source", "%source.index") catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 full decoder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    irw.load(writer, "b0", "i8", "%src0", "1") catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 full decoder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    try irw.indexedTableLoadI8(writer, "v0", "base64.full_table", "b0");
    try irw.pointerIndexAdvance(writer, "src1.index", "%source.index", "1");
    try irw.gep(writer, "src1", "i8", "%source", "%src1.index");
    try irw.load(writer, "b1", "i8", "%src1", "1");
    try irw.indexedTableLoadI8(writer, "v1", "base64.full_table", "b1");
    try irw.pointerIndexAdvance(writer, "src2.index", "%source.index", "2");
    try irw.gep(writer, "src2", "i8", "%source", "%src2.index");
    try irw.load(writer, "b2", "i8", "%src2", "1");
    try irw.indexedTableLoadI8(writer, "v2", "base64.full_table", "b2");
    try irw.pointerIndexAdvance(writer, "src3.index", "%source.index", "3");
    try irw.gep(writer, "src3", "i8", "%source", "%src3.index");
    try irw.load(writer, "b3", "i8", "%src3", "1");
    try irw.indexedTableLoadI8(writer, "v3", "base64.full_table", "b3");
    writer.print(
        \\  %b2.pad = icmp eq i8 %b2, 61
        \\  %b3.pad = icmp eq i8 %b3, 61
        \\  %v0.valid = icmp ne i8 %v0.word, -1
        \\  %v1.valid = icmp ne i8 %v1.word, -1
        \\  %v2.valid.raw = icmp ne i8 %v2.word, -1
        \\  %v2.valid = select i1 %b2.pad, i1 true, i1 %v2.valid.raw
        \\  %v3.valid.raw = icmp ne i8 %v3.word, -1
        \\  %v3.valid = select i1 %b3.pad, i1 true, i1 %v3.valid.raw
        \\  %pad.valid = select i1 %b2.pad, i1 %b3.pad, i1 true
        \\  %valid01 = and i1 %v0.valid, %v1.valid
        \\  %valid012 = and i1 %valid01, %v2.valid
        \\  %valid0123 = and i1 %valid012, %v3.valid
        \\  %valid = and i1 %valid0123, %pad.valid
        \\  %output.required.23 = select i1 %b3.pad, i64 2, i64 3
        \\  %output.required = select i1 %b2.pad, i64 1, i64 %output.required.23
        \\  %output.len.ok = icmp uge i64 %output_len, %output.required
        \\  %valid.output = and i1 %valid, %output.len.ok
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 full decoder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    irw.condBr(writer, "valid.output", "decode_values", "decode_fail") catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 full decoder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    irw.block(writer, "decode_values") catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 full decoder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    try irw.byteMask(writer, "v0.masked", "%v0.word", "63");
    try irw.byteMask(writer, "v1.masked", "%v1.word", "63");
    try irw.byteMask(writer, "v2.masked", "%v2.word", "63");
    try irw.byteMask(writer, "v3.masked", "%v3.word", "63");
    writer.print(
        \\  %v2.value = select i1 %b2.pad, i8 0, i8 %v2.masked
        \\  %v3.value = select i1 %b3.pad, i8 0, i8 %v3.masked
        \\  %v0.i32 = zext i8 %v0.masked to i32
        \\  %v1.i32 = zext i8 %v1.masked to i32
        \\  %v2.i32 = zext i8 %v2.value to i32
        \\  %v3.i32 = zext i8 %v3.value to i32
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 full decoder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    try irw.shift(writer, "shift0", "shl", "i32", "%v0.i32", "18");
    try irw.shift(writer, "shift1", "shl", "i32", "%v1.i32", "12");
    writer.print(
        \\  %word1 = or i32 %shift0, %shift1
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 full decoder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    try irw.shift(writer, "shift2", "shl", "i32", "%v2.i32", "6");
    writer.print(
        \\  %word2 = or i32 %word1, %shift2
        \\  %word = or i32 %word2, %v3.i32
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 full decoder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    try irw.shift(writer, "byte0.shift", "lshr", "i32", "%word", "16");
    try irw.trunc(writer, "byte0", "i32", "%byte0.shift", "i8");
    try writeBase64OutputStore(writer, "dst0", "%output", "%output.index", "i8", "%byte0");
    writer.print(
        \\  %output.next = add i64 %output.index, %output.required
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 full decoder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    irw.condBr(writer, "b2.pad", "decode_done", "store_byte1") catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 full decoder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    irw.block(writer, "store_byte1") catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 full decoder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    try irw.pointerIndexAdvance(writer, "dst1.index", "%output.index", "1");
    try irw.shift(writer, "byte1.shift", "lshr", "i32", "%word", "8");
    try irw.trunc(writer, "byte1", "i32", "%byte1.shift", "i8");
    try writeBase64OutputStore(writer, "dst1", "%output", "%dst1.index", "i8", "%byte1");
    irw.condBr(writer, "b3.pad", "decode_done", "store_byte2") catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 full decoder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    irw.block(writer, "store_byte2") catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 full decoder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    try irw.pointerIndexAdvance(writer, "dst2.index", "%output.index", "2");
    try irw.trunc(writer, "byte2", "i32", "%word", "i8");
    try writeBase64OutputStore(writer, "dst2", "%output", "%dst2.index", "i8", "%byte2");
    try irw.pointerIndexAdvance(writer, "source.next", "%source.index", "4");
    writer.print(
        \\  %done = icmp eq i64 %source.next, %source_len
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 full decoder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    irw.condBr(writer, "done", "decode_done", "decode_latch") catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 full decoder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    irw.block(writer, "decode_latch") catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 full decoder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    irw.br(writer, "decode_loop") catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 full decoder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    irw.block(writer, "decode_done") catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 full decoder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    writer.print(
        \\  ret i64 %output.next
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 full decoder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    irw.block(writer, "decode_fail") catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 full decoder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
    writer.print(
        \\  ret i64 -1
        \\}}
        \\
    , .{}) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 full decoder external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeReleaseSmallRuntimeBase64DecodeStepIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeBase64DecodeStepStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 decode-step external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeBase64DecodeStepStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.global("base64.decode_step_table", "private unnamed_addr", .{ .text = "[16 x i32]" }, "[i32 0, i32 248, i32 -16777216, i32 252, i32 0, i32 4096, i32 -16777216, i32 61443, i32 0, i32 8192, i32 -16777216, i32 12586752, i32 0, i32 196608, i32 -16777216, i32 4128768]", "4");
    try writer.writeAll("\n");
    var function = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var entry = try function.block("entry");
    _ = try entry.gep2("p0", .{ .text = "[16 x i32]" }, sib.global(.ptr, "@base64.decode_step_table"), sib.int(.i64, "0"), sib.int(.i64, "0"));
    _ = try entry.load("v0", .i32, sib.local(.ptr, "%p0"), "4");
    _ = try entry.gep2("p1", .{ .text = "[16 x i32]" }, sib.global(.ptr, "@base64.decode_step_table"), sib.int(.i64, "0"), sib.int(.i64, "5"));
    _ = try entry.load("v1", .i32, sib.local(.ptr, "%p1"), "4");
    _ = try entry.binary("word1", "or", .i32, sib.local(.i32, "%v1"), sib.local(.i32, "%v0"));
    _ = try entry.gep2("p2", .{ .text = "[16 x i32]" }, sib.global(.ptr, "@base64.decode_step_table"), sib.int(.i64, "0"), sib.int(.i64, "9"));
    _ = try entry.load("v2", .i32, sib.local(.ptr, "%p2"), "4");
    _ = try entry.binary("word2", "or", .i32, sib.local(.i32, "%word1"), sib.local(.i32, "%v2"));
    _ = try entry.gep2("p3", .{ .text = "[16 x i32]" }, sib.global(.ptr, "@base64.decode_step_table"), sib.int(.i64, "0"), sib.int(.i64, "13"));
    _ = try entry.load("v3", .i32, sib.local(.ptr, "%p3"), "4");
    _ = try entry.binary("word", "or", .i32, sib.local(.i32, "%word2"), sib.local(.i32, "%v3"));
    _ = try entry.icmp("valid", "ult", .i32, sib.local(.i32, "%word"), sib.int(.i32, "16777216"));
    _ = try entry.select("ret", sib.local(.i1, "%valid"), .i32, sib.int(.i32, "0"), sib.int(.i32, "1"));
    try entry.ret(sib.local(.i32, "%ret"));
    try function.end();
}

pub fn writeReleaseSmallRuntimeBase64StoreStepIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeBase64StoreStepStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 store-step external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeBase64StoreStepStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.global("base64.decode_output", "private unnamed_addr", .i32, "0", "4");
    try writer.writeAll("\n");
    var function = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var entry = try function.block("entry");
    _ = try entry.gep("dst", .{ .text = "[1 x i8]" }, sib.global(.ptr, "@base64.decode_output"), .i64, sib.int(.i64, "0"));
    try entry.store(sib.int(.i32, "2105344"), sib.local(.ptr, "%dst"), "1");
    _ = try entry.load("check", .i32, sib.local(.ptr, "%dst"), "1");
    _ = try entry.icmp("ok", "eq", .i32, sib.local(.i32, "%check"), sib.int(.i32, "2105344"));
    _ = try entry.select("ret", sib.local(.i1, "%ok"), .i32, sib.int(.i32, "0"), sib.int(.i32, "1"));
    try entry.ret(sib.local(.i32, "%ret"));
    try function.end();
}

pub fn writeReleaseSmallRuntimeBase64ResidualByteStepIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeBase64ResidualByteStepStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 residual-byte external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeBase64ResidualByteStepStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.global("base64.residual_output", "private unnamed_addr", .i32, "0", "4");
    try writer.writeAll("\n");
    var function = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var entry = try function.block("entry");
    _ = try entry.gep("dst", .{ .text = "[1 x i8]" }, sib.global(.ptr, "@base64.residual_output"), .i64, sib.int(.i64, "0"));
    try entry.store(sib.int(.i8, "63"), sib.local(.ptr, "%dst"), "1");
    _ = try entry.load("check", .i8, sib.local(.ptr, "%dst"), "1");
    _ = try entry.icmp("ok", "eq", .i8, sib.local(.i8, "%check"), sib.int(.i8, "63"));
    _ = try entry.select("ret", sib.local(.i1, "%ok"), .i32, sib.int(.i32, "0"), sib.int(.i32, "1"));
    try entry.ret(sib.local(.i32, "%ret"));
    try function.end();
}

pub fn writeReleaseSmallRuntimeBase64PaddingTailStepIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeBase64PaddingTailStepStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 padding-tail external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeBase64PaddingTailStepStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.global("base64.padding_tail", "private unnamed_addr", .i32, "61", "4");
    try writer.writeAll("\n");
    var function = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var entry = try function.block("entry");
    _ = try entry.gep("src", .{ .text = "[1 x i8]" }, sib.global(.ptr, "@base64.padding_tail"), .i64, sib.int(.i64, "0"));
    _ = try entry.load("byte", .i8, sib.local(.ptr, "%src"), "1");
    _ = try entry.icmp("is_pad", "eq", .i8, sib.local(.i8, "%byte"), sib.int(.i8, "61"));
    _ = try entry.select("ret", sib.local(.i1, "%is_pad"), .i32, sib.int(.i32, "0"), sib.int(.i32, "1"));
    try entry.ret(sib.local(.i32, "%ret"));
    try function.end();
}

pub fn writeReleaseSmallRuntimeBase64PaddingLoopStepIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeBase64PaddingLoopStepStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 padding-loop external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeBase64PaddingLoopStepStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.global("base64.padding_loop", "private unnamed_addr", .i32, "61", "4");
    try writer.writeAll("\n");
    var function = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var entry = try function.block("entry");
    try entry.br("loop");
    try writer.writeAll("\n");
    var loop = try function.block("loop");
    _ = try loop.phi2("index", .i64, sib.int(.i64, "0"), "entry", sib.local(.i64, "%next"), "body");
    _ = try loop.icmp("done", "eq", .i64, sib.local(.i64, "%index"), sib.int(.i64, "2"));
    try loop.condBr(sib.local(.i1, "%done"), "exit", "body");
    try writer.writeAll("\n");
    var body = try function.block("body");
    _ = try body.gep("src", .{ .text = "[1 x i8]" }, sib.global(.ptr, "@base64.padding_loop"), .i64, sib.int(.i64, "0"));
    _ = try body.load("byte", .i8, sib.local(.ptr, "%src"), "1");
    _ = try body.icmp("is_pad", "eq", .i8, sib.local(.i8, "%byte"), sib.int(.i8, "61"));
    _ = try body.binary("next", "add", .i64, sib.local(.i64, "%index"), sib.int(.i64, "1"));
    try body.condBr(sib.local(.i1, "%is_pad"), "loop", "fail");
    try writer.writeAll("\n");
    var fail = try function.block("fail");
    try fail.ret(sib.int(.i32, "1"));
    try writer.writeAll("\n");
    var exit = try function.block("exit");
    try exit.ret(sib.int(.i32, "0"));
    try function.end();
}

pub fn writeReleaseSmallRuntimeBase64PaddingLengthStepIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeBase64PaddingLengthStepStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 padding-length external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeBase64PaddingLengthStepStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.global("base64.padding_length_tail", "private unnamed_addr", .i32, "15677", "4");
    try writer.writeAll("\n");
    var function = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var entry = try function.block("entry");
    _ = try entry.gep("end", .{ .text = "[1 x i8]" }, sib.global(.ptr, "@base64.padding_length_tail"), .i64, sib.int(.i64, "2"));
    _ = try entry.gep("last_ptr", .i8, sib.local(.ptr, "%end"), .i64, sib.int(.i64, "-1"));
    _ = try entry.load("last", .i8, sib.local(.ptr, "%last_ptr"), "1");
    _ = try entry.icmp("last_eq", "eq", .i8, sib.local(.i8, "%last"), sib.int(.i8, "61"));
    _ = try entry.cast("last_adj", "sext", sib.local(.i1, "%last_eq"), .i64);
    _ = try entry.binary("base", "add", .i64, sib.int(.i64, "6"), sib.local(.i64, "%last_adj"));
    _ = try entry.gep("second_ptr", .i8, sib.local(.ptr, "%end"), .i64, sib.int(.i64, "-2"));
    _ = try entry.load("second", .i8, sib.local(.ptr, "%second_ptr"), "1");
    _ = try entry.icmp("second_eq", "eq", .i8, sib.local(.i8, "%second"), sib.int(.i8, "61"));
    _ = try entry.cast("second_adj", "sext", sib.local(.i1, "%second_eq"), .i64);
    _ = try entry.binary("total", "add", .i64, sib.local(.i64, "%base"), sib.local(.i64, "%second_adj"));
    _ = try entry.icmp("ok", "eq", .i64, sib.local(.i64, "%total"), sib.int(.i64, "8"));
    _ = try entry.select("ret", sib.local(.i1, "%ok"), .i32, sib.int(.i32, "0"), sib.int(.i32, "1"));
    try entry.ret(sib.local(.i32, "%ret"));
    try function.end();
}

pub fn writeReleaseSmallRuntimeBase64ChunkGuardStepIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeBase64ChunkGuardStepStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 chunk-guard external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeBase64ChunkGuardStepStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    var function = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var entry = try function.block("entry");
    _ = try entry.binary("source_next", "add nuw", .i64, sib.int(.i64, "0"), sib.int(.i64, "16"));
    _ = try entry.icmp("source_ok", "ult", .i64, sib.local(.i64, "%source_next"), sib.int(.i64, "64"));
    _ = try entry.binary("output_next", "add nuw", .i64, sib.int(.i64, "0"), sib.int(.i64, "15"));
    _ = try entry.icmp("output_ok", "ult", .i64, sib.local(.i64, "%output_next"), sib.int(.i64, "63"));
    _ = try entry.select("wide_ok", sib.local(.i1, "%source_ok"), .i1, sib.local(.i1, "%output_ok"), sib.int(.i1, "0"));
    _ = try entry.select("ret", sib.local(.i1, "%wide_ok"), .i32, sib.int(.i32, "0"), sib.int(.i32, "1"));
    try entry.ret(sib.local(.i32, "%ret"));
    try function.end();
}

pub fn writeReleaseSmallRuntimeBase64SourceStrideStepIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeBase64SourceStrideStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 source-stride external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeBase64SourceStrideStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.global("base64.source_stride_input", "private unnamed_addr", .i32, "0", "4");
    try module.global("base64.source_stride_table", "private unnamed_addr", .{ .text = "[8 x i32]" }, "[i32 42, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0]", "4");
    try writer.writeAll("\n");
    var function = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var entry = try function.block("entry");
    _ = try entry.gep("src", .i8, sib.global(.ptr, "@base64.source_stride_input"), .i64, sib.int(.i64, "4"));
    _ = try entry.load("byte", .i8, sib.local(.ptr, "%src"), "1");
    _ = try entry.cast("idx", "zext", sib.local(.i8, "%byte"), .i64);
    _ = try entry.gep("entry_ptr", .{ .text = "[4 x i8]" }, sib.global(.ptr, "@base64.source_stride_table"), .i64, sib.local(.i64, "%idx"));
    _ = try entry.load("word", .i32, sib.local(.ptr, "%entry_ptr"), "4");
    _ = try entry.icmp("ok", "eq", .i32, sib.local(.i32, "%word"), sib.int(.i32, "42"));
    _ = try entry.select("ret", sib.local(.i1, "%ok"), .i32, sib.int(.i32, "0"), sib.int(.i32, "1"));
    try entry.ret(sib.local(.i32, "%ret"));
    try function.end();
}

pub fn writeReleaseSmallRuntimeBase64SourceBundleStepIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeBase64SourceBundleStructuredModule(writer, "source_bundle", "base64.source_bundle_input", "4") catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 source-bundle external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeReleaseSmallRuntimeBase64NextSourceBundleStepIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeBase64SourceBundleStructuredModule(writer, "next_source_bundle", "base64.next_source_bundle_input", "8") catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 next-source-bundle external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeReleaseSmallRuntimeBase64ThirdSourceBundleStepIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeBase64SourceBundleStructuredModule(writer, "third_source_bundle", "base64.third_source_bundle_input", "12") catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 third-source-bundle external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeBase64SourceBundleStructuredModule(writer: *std.Io.Writer, prefix: []const u8, input_symbol: []const u8, first_offset: []const u8) !void {
    var module = sib.Module.init(writer);
    try module.global(input_symbol, "private unnamed_addr", .i32, "0", "4");
    const suffixes = [_][]const u8{ "0", "1", "2", "3" };
    const values = [_][]const u8{ "0", "4096", "8192", "196608" };
    for (suffixes, values) |suffix, value| {
        const table_name = try std.fmt.allocPrint(std.heap.page_allocator, "base64.{s}_table{s}", .{ prefix, suffix });
        const initializer = try std.fmt.allocPrint(std.heap.page_allocator, "[i32 {s}]", .{value});
        try module.global(table_name, "private unnamed_addr", .{ .text = "[1 x i32]" }, initializer, "4");
    }
    try writer.writeAll("\n");
    var function = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var entry = try function.block("entry");
    try writeBase64FourByteBundleStructured(&entry, input_symbol, first_offset, prefix);
    _ = try entry.select("ret", sib.local(.i1, "%valid"), .i32, sib.int(.i32, "0"), sib.int(.i32, "1"));
    try entry.ret(sib.local(.i32, "%ret"));
    try function.end();
}

fn writeBase64FourByteBundleStructured(entry: *sib.Block, input_symbol: []const u8, first_offset: []const u8, prefix: []const u8) !void {
    const input_ref = try std.fmt.allocPrint(std.heap.page_allocator, "@{s}", .{input_symbol});
    _ = try entry.gep("src0", .i8, sib.global(.ptr, input_ref), .i64, sib.int(.i64, first_offset));
    _ = try entry.load("byte0", .i8, sib.local(.ptr, "%src0"), "1");
    try writeBase64BundleTableLoad(entry, "word0", prefix, "0", "%byte0");
    _ = try entry.gep("src1", .i8, sib.local(.ptr, "%src0"), .i64, sib.int(.i64, "1"));
    _ = try entry.load("byte1", .i8, sib.local(.ptr, "%src1"), "1");
    try writeBase64BundleTableLoad(entry, "word1", prefix, "1", "%byte1");
    _ = try entry.binary("merged1", "or", .i32, sib.local(.i32, "%word1.word"), sib.local(.i32, "%word0.word"));
    _ = try entry.gep("src2", .i8, sib.local(.ptr, "%src0"), .i64, sib.int(.i64, "2"));
    _ = try entry.load("byte2", .i8, sib.local(.ptr, "%src2"), "1");
    try writeBase64BundleTableLoad(entry, "word2", prefix, "2", "%byte2");
    _ = try entry.binary("merged2", "or", .i32, sib.local(.i32, "%merged1"), sib.local(.i32, "%word2.word"));
    _ = try entry.gep("src3", .i8, sib.local(.ptr, "%src0"), .i64, sib.int(.i64, "3"));
    _ = try entry.load("byte3", .i8, sib.local(.ptr, "%src3"), "1");
    try writeBase64BundleTableLoad(entry, "word3", prefix, "3", "%byte3");
    _ = try entry.binary("word", "or", .i32, sib.local(.i32, "%merged2"), sib.local(.i32, "%word3.word"));
    _ = try entry.icmp("valid", "ult", .i32, sib.local(.i32, "%word"), sib.int(.i32, "16777216"));
}

fn writeBase64BundleTableLoad(entry: *sib.Block, result_prefix: []const u8, prefix: []const u8, table_suffix: []const u8, byte_ref: []const u8) !void {
    const idx = try std.fmt.allocPrint(std.heap.page_allocator, "{s}.idx", .{result_prefix});
    const entry_name = try std.fmt.allocPrint(std.heap.page_allocator, "{s}.entry", .{result_prefix});
    const word = try std.fmt.allocPrint(std.heap.page_allocator, "{s}.word", .{result_prefix});
    const table_ref = try std.fmt.allocPrint(std.heap.page_allocator, "@base64.{s}_table{s}", .{ prefix, table_suffix });
    _ = try entry.cast(idx, "zext", sib.local(.i8, byte_ref), .i64);
    const idx_ref = try std.fmt.allocPrint(std.heap.page_allocator, "%{s}", .{idx});
    _ = try entry.gep(entry_name, .{ .text = "[4 x i8]" }, sib.global(.ptr, table_ref), .i64, sib.local(.i64, idx_ref));
    const entry_ref = try std.fmt.allocPrint(std.heap.page_allocator, "%{s}", .{entry_name});
    _ = try entry.load(word, .i32, sib.local(.ptr, entry_ref), "4");
}

pub fn writeReleaseSmallRuntimeBase64BitBufferStoreStepIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeBase64BitBufferStoreStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 bit-buffer-store external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeBase64BitBufferStoreStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.global("base64.bit_buffer_word0", "private unnamed_addr", .i32, "1", "4");
    try module.global("base64.bit_buffer_word1", "private unnamed_addr", .i32, "2", "4");
    try module.global("base64.bit_buffer_word2", "private unnamed_addr", .i32, "3", "4");
    try module.global("base64.bit_buffer_word3", "private unnamed_addr", .i32, "4", "4");
    try module.global("base64.bit_buffer_output", "private unnamed_addr", .i32, "0", "4");
    try writer.writeAll("\n");
    var function = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var entry = try function.block("entry");
    _ = try entry.load("word0.raw", .i32, sib.global(.ptr, "@base64.bit_buffer_word0"), "4");
    _ = try entry.cast("word0", "zext", sib.local(.i32, "%word0.raw"), .i128);
    _ = try entry.load("word3.raw", .i32, sib.global(.ptr, "@base64.bit_buffer_word3"), "4");
    _ = try entry.castFlags("word3", "zext nneg", sib.local(.i32, "%word3.raw"), .i128);
    _ = try entry.load("word1.raw", .i32, sib.global(.ptr, "@base64.bit_buffer_word1"), "4");
    _ = try entry.castFlags("word1", "zext nneg", sib.local(.i32, "%word1.raw"), .i128);
    _ = try entry.binary("shift1", "shl nsw nuw", .i128, sib.local(.i128, "%word1"), sib.int(.i128, "24"));
    _ = try entry.binary("merged1", "or disjoint", .i128, sib.local(.i128, "%shift1"), sib.local(.i128, "%word0"));
    _ = try entry.load("word2.raw", .i32, sib.global(.ptr, "@base64.bit_buffer_word2"), "4");
    _ = try entry.castFlags("word2", "zext nneg", sib.local(.i32, "%word2.raw"), .i128);
    _ = try entry.binary("shift2", "shl nsw nuw", .i128, sib.local(.i128, "%word2"), sib.int(.i128, "48"));
    _ = try entry.binary("merged2", "or disjoint", .i128, sib.local(.i128, "%merged1"), sib.local(.i128, "%shift2"));
    _ = try entry.binary("shift3", "shl nsw nuw", .i128, sib.local(.i128, "%word3"), sib.int(.i128, "72"));
    _ = try entry.binary("merged", "or disjoint", .i128, sib.local(.i128, "%merged2"), sib.local(.i128, "%shift3"));
    _ = try entry.gep("dst", .{ .text = "[1 x i8]" }, sib.global(.ptr, "@base64.bit_buffer_output"), .i64, sib.int(.i64, "0"));
    try entry.store(sib.local(.i128, "%merged"), sib.local(.ptr, "%dst"), "1");
    try entry.ret(sib.int(.i32, "0"));
    try function.end();
}

pub fn writeReleaseSmallRuntimeBase64LoopAdvanceStepIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeBase64LoopAdvanceStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 loop-advance external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeBase64LoopAdvanceStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.global("base64.loop_advance_output", "private unnamed_addr", .i64, "0", "8");
    try module.global("base64.loop_advance_source", "private unnamed_addr", .i64, "16", "8");
    try writer.writeAll("\n");
    var function = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var entry = try function.block("entry");
    _ = try entry.load("out.start", .i64, sib.global(.ptr, "@base64.loop_advance_output"), "8");
    _ = try entry.load("src.start", .i64, sib.global(.ptr, "@base64.loop_advance_source"), "8");
    try entry.br("loop");
    try writer.writeAll("\n");
    var loop = try function.block("loop");
    _ = try loop.phi2("out", .i64, sib.local(.i64, "%out.start"), "entry", sib.local(.i64, "%out.next"), "loop");
    _ = try loop.phi2("src", .i64, sib.local(.i64, "%src.start"), "entry", sib.local(.i64, "%src.next"), "loop");
    _ = try loop.binary("out.next", "add nuw", .i64, sib.local(.i64, "%out"), sib.int(.i64, "12"));
    _ = try loop.binary("src.next", "add", .i64, sib.local(.i64, "%src"), sib.int(.i64, "-16"));
    _ = try loop.icmp("done", "eq", .i64, sib.local(.i64, "%out.next"), sib.int(.i64, "12"));
    try loop.condBr(sib.local(.i1, "%done"), "exit", "loop");
    try writer.writeAll("\n");
    var exit = try function.block("exit");
    _ = try exit.icmp("src.ok", "eq", .i64, sib.local(.i64, "%src.next"), sib.int(.i64, "0"));
    _ = try exit.select("ret", sib.local(.i1, "%src.ok"), .i32, sib.int(.i32, "0"), sib.int(.i32, "1"));
    try exit.ret(sib.local(.i32, "%ret"));
    try function.end();
}

pub fn writeReleaseSmallRuntimeBase64ResidualGuardStepIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeBase64ResidualGuardStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 residual-guard external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeBase64ResidualGuardStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.global("base64.residual_guard_source_index", "private unnamed_addr", .i64, "0", "8");
    try module.global("base64.residual_guard_output_index", "private unnamed_addr", .i64, "0", "8");
    try module.global("base64.residual_guard_source_len", "private unnamed_addr", .i64, "8", "8");
    try module.global("base64.residual_guard_output_len", "private unnamed_addr", .i64, "8", "8");
    try module.global("base64.residual_guard_source", "private unnamed_addr", .{ .text = "[1 x i8]" }, "c\"A\"", "1");
    try writer.writeAll("\n");
    var function = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var entry = try function.block("entry");
    _ = try entry.load("source.index", .i64, sib.global(.ptr, "@base64.residual_guard_source_index"), "8");
    _ = try entry.load("output.index", .i64, sib.global(.ptr, "@base64.residual_guard_output_index"), "8");
    _ = try entry.load("source.len", .i64, sib.global(.ptr, "@base64.residual_guard_source_len"), "8");
    _ = try entry.load("output.len", .i64, sib.global(.ptr, "@base64.residual_guard_output_len"), "8");
    _ = try entry.binary("source.next", "add nuw", .i64, sib.local(.i64, "%source.index"), sib.int(.i64, "4"));
    _ = try entry.icmp("source.ok", "ult", .i64, sib.local(.i64, "%source.next"), sib.local(.i64, "%source.len"));
    _ = try entry.binary("output.next", "add nuw", .i64, sib.local(.i64, "%output.index"), sib.int(.i64, "3"));
    _ = try entry.icmp("output.ok", "ult", .i64, sib.local(.i64, "%output.next"), sib.local(.i64, "%output.len"));
    _ = try entry.select("guard", sib.local(.i1, "%source.ok"), .i1, sib.local(.i1, "%output.ok"), sib.int(.i1, "0"));
    _ = try entry.gep("src.ptr", .{ .text = "[1 x i8]" }, sib.global(.ptr, "@base64.residual_guard_source"), .i64, sib.local(.i64, "%source.index"));
    try entry.condBr(sib.local(.i1, "%guard"), "decode", "done");
    try writer.writeAll("\n");
    var decode = try function.block("decode");
    _ = try decode.load("byte", .i8, sib.local(.ptr, "%src.ptr"), "1");
    _ = try decode.icmp("byte.ok", "eq", .i8, sib.local(.i8, "%byte"), sib.int(.i8, "65"));
    _ = try decode.select("ret.ok", sib.local(.i1, "%byte.ok"), .i32, sib.int(.i32, "0"), sib.int(.i32, "2"));
    try decode.ret(sib.local(.i32, "%ret.ok"));
    try writer.writeAll("\n");
    var done = try function.block("done");
    try done.ret(sib.int(.i32, "1"));
    try function.end();
}

pub fn writeReleaseSmallRuntimeBase64ResidualBundleStepIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeBase64SourceBundleStructuredModule(writer, "residual_bundle", "base64.residual_bundle_input", "0") catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 residual-bundle external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeReleaseSmallRuntimeBase64ResidualStoreStepIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeBase64ResidualStoreStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 residual-store external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeBase64ResidualStoreStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.global("base64.residual_store_output", "private unnamed_addr", .i32, "0", "4");
    try module.global("base64.residual_store_word", "private unnamed_addr", .i32, "2105344", "4");
    try module.global("base64.residual_store_remaining", "private unnamed_addr", .i64, "4", "8");
    try writer.writeAll("\n");
    var function = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var entry = try function.block("entry");
    _ = try entry.load("word", .i32, sib.global(.ptr, "@base64.residual_store_word"), "4");
    _ = try entry.gep("dst", .{ .text = "[1 x i8]" }, sib.global(.ptr, "@base64.residual_store_output"), .i64, sib.int(.i64, "0"));
    try entry.store(sib.local(.i32, "%word"), sib.local(.ptr, "%dst"), "1");
    _ = try entry.load("check", .i32, sib.local(.ptr, "%dst"), "1");
    _ = try entry.icmp("store.ok", "eq", .i32, sib.local(.i32, "%check"), sib.local(.i32, "%word"));
    _ = try entry.load("remaining", .i64, sib.global(.ptr, "@base64.residual_store_remaining"), "8");
    _ = try entry.binary("next", "add", .i64, sib.local(.i64, "%remaining"), sib.int(.i64, "-4"));
    _ = try entry.icmp("next.ok", "eq", .i64, sib.local(.i64, "%next"), sib.int(.i64, "0"));
    _ = try entry.select("ok", sib.local(.i1, "%store.ok"), .i1, sib.local(.i1, "%next.ok"), sib.int(.i1, "0"));
    _ = try entry.select("ret", sib.local(.i1, "%ok"), .i32, sib.int(.i32, "0"), sib.int(.i32, "1"));
    try entry.ret(sib.local(.i32, "%ret"));
    try function.end();
}

pub fn writeReleaseSmallRuntimeBase64ResidualLengthStepIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeBase64ResidualLengthStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 residual-length external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeBase64ResidualLengthStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.global("base64.residual_length_total", "private unnamed_addr", .i64, "8", "8");
    try module.global("base64.residual_length_index", "private unnamed_addr", .i64, "4", "8");
    try writer.writeAll("\n");
    var function = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var entry = try function.block("entry");
    _ = try entry.load("total", .i64, sib.global(.ptr, "@base64.residual_length_total"), "8");
    _ = try entry.load("index", .i64, sib.global(.ptr, "@base64.residual_length_index"), "8");
    _ = try entry.binary("remaining", "sub nuw", .i64, sib.local(.i64, "%total"), sib.local(.i64, "%index"));
    _ = try entry.icmp("ok", "eq", .i64, sib.local(.i64, "%remaining"), sib.int(.i64, "4"));
    _ = try entry.select("ret", sib.local(.i1, "%ok"), .i32, sib.int(.i32, "0"), sib.int(.i32, "1"));
    try entry.ret(sib.local(.i32, "%ret"));
    try function.end();
}

pub fn writeReleaseSmallRuntimeBase64ResidualTableCheckStepIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeBase64ResidualTableCheckStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 residual-table-check external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeBase64ResidualTableCheckStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.global("base64.residual_table_check_input", "private unnamed_addr", .{ .text = "[1 x i8]" }, "c\"\\00\"", "1");
    try module.global("base64.residual_table_check_table", "private unnamed_addr", .{ .text = "[1 x i8]" }, "c\"\\00\"", "1");
    try writer.writeAll("\n");
    var function = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var entry = try function.block("entry");
    _ = try entry.gep("src", .{ .text = "[1 x i8]" }, sib.global(.ptr, "@base64.residual_table_check_input"), .i64, sib.int(.i64, "0"));
    _ = try entry.load("byte", .i8, sib.local(.ptr, "%src"), "1");
    _ = try entry.cast("idx", "zext", sib.local(.i8, "%byte"), .i64);
    _ = try entry.gep("entry_ptr", .{ .text = "[1 x i8]" }, sib.global(.ptr, "@base64.residual_table_check_table"), .i64, sib.local(.i64, "%idx"));
    _ = try entry.load("entry", .i8, sib.local(.ptr, "%entry_ptr"), "1");
    _ = try entry.icmp("invalid", "eq", .i8, sib.local(.i8, "%entry"), sib.int(.i8, "-1"));
    _ = try entry.select("ret", sib.local(.i1, "%invalid"), .i32, sib.int(.i32, "1"), sib.int(.i32, "0"));
    try entry.ret(sib.local(.i32, "%ret"));
    try function.end();
}

pub fn writeReleaseSmallRuntimeBase64ResidualAccumulatorStepIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeBase64ResidualAccumulatorStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 residual-accumulator external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeBase64ResidualAccumulatorStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.global("base64.residual_accumulator_bits", "private unnamed_addr", .i16, "1", "2");
    try module.global("base64.residual_accumulator_entry", "private unnamed_addr", .i8, "2", "1");
    try module.global("base64.residual_accumulator_count", "private unnamed_addr", .i8, "0", "1");
    try writer.writeAll("\n");
    var function = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var entry = try function.block("entry");
    _ = try entry.load("bits.raw", .i16, sib.global(.ptr, "@base64.residual_accumulator_bits"), "2");
    _ = try entry.cast("bits", "trunc", sib.local(.i16, "%bits.raw"), .i12);
    _ = try entry.binary("shifted", "shl", .i12, sib.local(.i12, "%bits"), sib.int(.i12, "6"));
    _ = try entry.load("entry.raw", .i8, sib.global(.ptr, "@base64.residual_accumulator_entry"), "1");
    _ = try entry.cast("entry.bits", "zext", sib.local(.i8, "%entry.raw"), .i12);
    _ = try entry.binary("next.bits", "add nuw", .i12, sib.local(.i12, "%shifted"), sib.local(.i12, "%entry.bits"));
    try entry.store(sib.local(.i12, "%next.bits"), sib.global(.ptr, "@base64.residual_accumulator_bits"), "2");
    _ = try entry.load("count.raw", .i8, sib.global(.ptr, "@base64.residual_accumulator_count"), "1");
    _ = try entry.cast("count", "trunc", sib.local(.i8, "%count.raw"), .i4);
    _ = try entry.binary("next.count", "add nuw", .i4, sib.local(.i4, "%count"), sib.int(.i4, "6"));
    try entry.store(sib.local(.i4, "%next.count"), sib.global(.ptr, "@base64.residual_accumulator_count"), "1");
    _ = try entry.icmp("ok", "eq", .i4, sib.local(.i4, "%next.count"), sib.int(.i4, "6"));
    _ = try entry.select("ret", sib.local(.i1, "%ok"), .i32, sib.int(.i32, "0"), sib.int(.i32, "1"));
    try entry.ret(sib.local(.i32, "%ret"));
    try function.end();
}

pub fn writeReleaseSmallRuntimeBase64ResidualLoopAdvanceStepIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeBase64ResidualLoopAdvanceStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 residual-loop-advance external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeBase64ResidualLoopAdvanceStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.global("base64.residual_loop_index", "private unnamed_addr", .i64, "0", "8");
    try writer.writeAll("\n");
    var function = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var entry = try function.block("entry");
    _ = try entry.load("index", .i64, sib.global(.ptr, "@base64.residual_loop_index"), "8");
    _ = try entry.binary("next", "add nuw", .i64, sib.local(.i64, "%index"), sib.int(.i64, "1"));
    _ = try entry.icmp("ok", "eq", .i64, sib.local(.i64, "%next"), sib.int(.i64, "1"));
    _ = try entry.select("ret", sib.local(.i1, "%ok"), .i32, sib.int(.i32, "0"), sib.int(.i32, "1"));
    try entry.ret(sib.local(.i32, "%ret"));
    try function.end();
}

pub fn writeReleaseSmallRuntimeBase64ResidualPaddingCheckStepIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeBase64ResidualPaddingCheckStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 residual-padding-check external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeBase64ResidualPaddingCheckStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.global("base64.residual_padding_index", "private unnamed_addr", .i64, "1", "8");
    try module.global("base64.residual_padding_base", "private unnamed_addr", .i64, "3", "8");
    try module.global("base64.residual_padding_byte", "private unnamed_addr", .i8, "61", "1");
    try writer.writeAll("\n");
    var function = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var entry = try function.block("entry");
    _ = try entry.load("index", .i64, sib.global(.ptr, "@base64.residual_padding_index"), "8");
    _ = try entry.load("base", .i64, sib.global(.ptr, "@base64.residual_padding_base"), "8");
    _ = try entry.binary("offset", "add nuw", .i64, sib.local(.i64, "%index"), sib.local(.i64, "%base"));
    _ = try entry.icmp("offset.ok", "eq", .i64, sib.local(.i64, "%offset"), sib.int(.i64, "4"));
    _ = try entry.load("byte", .i8, sib.global(.ptr, "@base64.residual_padding_byte"), "1");
    _ = try entry.icmp("pad.ok", "eq", .i8, sib.local(.i8, "%byte"), sib.int(.i8, "61"));
    _ = try entry.select("ok", sib.local(.i1, "%offset.ok"), .i1, sib.local(.i1, "%pad.ok"), sib.int(.i1, "0"));
    _ = try entry.select("ret", sib.local(.i1, "%ok"), .i32, sib.int(.i32, "0"), sib.int(.i32, "1"));
    try entry.ret(sib.local(.i32, "%ret"));
    try function.end();
}

pub fn writeReleaseSmallRuntimeBase64ResidualFinalMaskStepIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeBase64ResidualFinalMaskStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 residual-final-mask external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeBase64ResidualFinalMaskStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.global("base64.residual_final_index", "private unnamed_addr", .i64, "0", "8");
    try module.global("base64.residual_final_remaining", "private unnamed_addr", .i64, "1", "8");
    try module.global("base64.residual_final_bits", "private unnamed_addr", .i16, "0", "2");
    try module.global("base64.residual_final_shift", "private unnamed_addr", .i8, "0", "1");
    try writer.writeAll("\n");
    var function = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var entry = try function.block("entry");
    _ = try entry.load("index", .i64, sib.global(.ptr, "@base64.residual_final_index"), "8");
    _ = try entry.load("remaining", .i64, sib.global(.ptr, "@base64.residual_final_remaining"), "8");
    _ = try entry.icmp("done", "uge", .i64, sib.local(.i64, "%index"), sib.local(.i64, "%remaining"));
    _ = try entry.load("bits.raw", .i16, sib.global(.ptr, "@base64.residual_final_bits"), "2");
    _ = try entry.cast("bits", "trunc", sib.local(.i16, "%bits.raw"), .i12);
    _ = try entry.load("shift.raw", .i8, sib.global(.ptr, "@base64.residual_final_shift"), "1");
    _ = try entry.binary("shift", "and", .i8, sib.local(.i8, "%shift.raw"), sib.int(.i8, "7"));
    _ = try entry.cast("shift.bits", "zext", sib.local(.i8, "%shift"), .i12);
    _ = try entry.binary("notmask", "shl nsw", .i12, sib.int(.i12, "-1"), sib.local(.i12, "%shift.bits"));
    _ = try entry.binary("mask", "xor", .i12, sib.local(.i12, "%notmask"), sib.int(.i12, "-1"));
    _ = try entry.binary("residual", "and", .i12, sib.local(.i12, "%bits"), sib.local(.i12, "%mask"));
    _ = try entry.icmp("has.residual", "ne", .i12, sib.local(.i12, "%residual"), sib.int(.i12, "0"));
    _ = try entry.binary("fail", "or", .i1, sib.local(.i1, "%done"), sib.local(.i1, "%has.residual"));
    _ = try entry.select("ret", sib.local(.i1, "%fail"), .i32, sib.int(.i32, "1"), sib.int(.i32, "0"));
    try entry.ret(sib.local(.i32, "%ret"));
    try function.end();
}

pub fn writeReleaseSmallRuntimeBase64ResidualPaddingLoopStepIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeBase64ResidualPaddingLoopStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 residual-padding-loop external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeBase64ResidualPaddingLoopStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.global("base64.residual_padding_loop_source", "private unnamed_addr", .{ .text = "[1 x i8]" }, "c\"=\"", "1");
    try module.global("base64.residual_padding_loop_start", "private unnamed_addr", .i64, "0", "8");
    try module.global("base64.residual_padding_loop_total", "private unnamed_addr", .i64, "1", "8");
    try module.global("base64.residual_padding_loop_index", "private unnamed_addr", .i64, "0", "8");
    try writer.writeAll("\n");
    var function = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var entry = try function.block("entry");
    _ = try entry.load("start", .i64, sib.global(.ptr, "@base64.residual_padding_loop_start"), "8");
    _ = try entry.load("total", .i64, sib.global(.ptr, "@base64.residual_padding_loop_total"), "8");
    _ = try entry.binary("limit", "sub nuw", .i64, sib.local(.i64, "%total"), sib.local(.i64, "%start"));
    _ = try entry.load("loop.index", .i64, sib.global(.ptr, "@base64.residual_padding_loop_index"), "8");
    _ = try entry.icmp("done", "eq", .i64, sib.local(.i64, "%loop.index"), sib.local(.i64, "%limit"));
    _ = try entry.gep("ptr", .{ .text = "[1 x i8]" }, sib.global(.ptr, "@base64.residual_padding_loop_source"), .i64, sib.local(.i64, "%loop.index"));
    _ = try entry.load("byte", .i8, sib.local(.ptr, "%ptr"), "1");
    _ = try entry.icmp("is.pad", "eq", .i8, sib.local(.i8, "%byte"), sib.int(.i8, "61"));
    _ = try entry.binary("next", "add", .i64, sib.local(.i64, "%loop.index"), sib.int(.i64, "1"));
    _ = try entry.icmp("next.ok", "eq", .i64, sib.local(.i64, "%next"), sib.int(.i64, "1"));
    _ = try entry.select("body.ok", sib.local(.i1, "%is.pad"), .i1, sib.local(.i1, "%next.ok"), sib.int(.i1, "0"));
    _ = try entry.select("ok", sib.local(.i1, "%done"), .i1, sib.int(.i1, "1"), sib.local(.i1, "%body.ok"));
    _ = try entry.select("ret", sib.local(.i1, "%ok"), .i32, sib.int(.i32, "0"), sib.int(.i32, "1"));
    try entry.ret(sib.local(.i32, "%ret"));
    try function.end();
}

pub fn writeReleaseSmallRuntimeBase64DecodeExitStepIrWriterBody(
    io: std.Io,
    writer: *std.Io.Writer,
    ir_path: []const u8,
) !void {
    writeBase64DecodeExitStructuredModule(writer) catch |err| {
        try fatal(io, "failed to write ReleaseSmall runtime base64 decode-exit external IR writer body {s}: {any}\n", .{ ir_path, err });
    };
}

pub fn writeBase64DecodeExitStructuredModule(writer: *std.Io.Writer) !void {
    var module = sib.Module.init(writer);
    try module.global("base64.decode_exit_bits", "private unnamed_addr", .i16, "0", "2");
    try module.global("base64.decode_exit_count", "private unnamed_addr", .i8, "0", "1");
    try writer.writeAll("\n");
    try module.declare(.void, "llvm.lifetime.end.p0", "ptr");
    try writer.writeAll("\n");
    var function = try module.function("dso_local ", .i32, "main", "", " local_unnamed_addr");
    var entry = try function.block("entry");
    try entry.lifetimeEnd(sib.global(.ptr, "@base64.decode_exit_count"));
    try entry.lifetimeEnd(sib.global(.ptr, "@base64.decode_exit_bits"));
    try entry.ret(sib.int(.i32, "0"));
    try function.end();
}
