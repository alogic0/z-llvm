const std = @import("std");
const ir = @import("../ir.zig");
const compilation = @import("../compilation.zig");
const machine = @import("../codegen/x86_64/machine.zig");
const tables = @import("../codegen/x86_64/constant_table.zig");
const pointers = @import("../codegen/x86_64/generic_cfg/pointer_values.zig");
const elf = @import("../mc/elf.zig");

const native_layout = "e-p:64:64-i64:64";

fn context(module: *const ir.Module) machine.ReadOnlyModuleContext {
    return .{
        .globals = module.globals.items,
        .named_types = module.named_types.items,
        .target_datalayout = module.target_datalayout,
        .functions = module.functions.items,
    };
}

fn tableText(layout: []const u8, count: usize, element: []const u8, value: []const u8, attrs: []const u8) ![]u8 {
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    const w = &output.writer;
    try w.print("target triple = \"x86_64-unknown-linux-gnu\"\ntarget datalayout = \"{s}\"\n%pair = type {{ double, double }}\n@table = private constant [{d} x {s}] [", .{ layout, count, element });
    for (0..count) |i| {
        if (i != 0) try w.writeAll(", ");
        try w.print("{s} {s}", .{ element, value });
    }
    try w.print("], {s}\n", .{attrs});
    return output.toOwnedSlice();
}

test "constant table access checks actual allocation stride under data-layout overrides" {
    const shape = tables.Description.init(.i16, 64, false).?;
    const source: ir.Type = .{ .aggregate = "[2 x i8]" };
    try std.testing.expect(tables.sourceStrideMatches(native_layout, source, shape));
    try std.testing.expect(tables.sourceStrideMatches("e-p:64:64-i8:8:32-i64:64", source, shape));
    for ([_]?[]const u8{
        null,
        "E-p:64:64-i64:64",
        "e-p:32:32-i64:64",
        "e-p:64:64:64:32-i64:64",
        "e-p:64:64-i8:32-i16:16-i64:64",
        "e-p:64:64-i8:32-i8:8-i64:64",
    }) |layout| try std.testing.expect(!tables.sourceStrideMatches(layout, source, shape));
}

test "constant table decoding declines incompatible serialized layouts before allocation" {
    const a = std.testing.allocator;
    const cases = [_]struct { count: usize, element: []const u8, value: []const u8, attrs: []const u8, override: []const u8, size: usize }{
        .{ .count = 64, .element = "i16", .value = "7", .attrs = "align 2", .override = "i16:32", .size = 128 },
        .{ .count = 16, .element = "double", .value = "1.0", .attrs = "align 8", .override = "f64:128", .size = 128 },
        .{ .count = 512, .element = "double", .value = "1.0", .attrs = "align 8", .override = "f64:128", .size = 4096 },
        .{ .count = 128, .element = "%pair", .value = "{ double 1.0, double 2.0 }", .attrs = "align 16", .override = "a:256", .size = 2048 },
    };
    for (cases) |case| {
        const text = try tableText(native_layout, case.count, case.element, case.value, case.attrs);
        defer a.free(text);
        var module = try ir.Module.parse(a, text);
        defer module.deinit();
        try module.verify();
        var ctx = context(&module);
        var decoded = (try tables.decodeSymbol(a, ctx, "table")).?;
        defer decoded.deinit(a);
        try std.testing.expectEqual(case.size, decoded.bytes.len);
        const changed = try std.fmt.allocPrint(a, "{s}-{s}", .{ native_layout, case.override });
        defer a.free(changed);
        ctx.target_datalayout = changed;
        try std.testing.expect(try tables.decodeSymbol(std.testing.failing_allocator, ctx, "table") == null);
    }
}

test "constant table recognition reserves only accesses with an applicable index proof" {
    const a = std.testing.allocator;
    const storage = try tableText(native_layout, 64, "i16", "7", "align 2");
    defer a.free(storage);
    const cases = [_]struct { before: []const u8 = "", source: []const u8 = "[2 x i8]", index: []const u8, reserved: bool }{
        .{ .index = "i64 %index", .reserved = false },
        .{ .index = "i64 17", .reserved = false },
        .{ .source = "i16", .index = "i64 %index", .reserved = false },
        .{ .source = "[64 x i16]", .index = "i64 0, i64 %index", .reserved = false },
        .{ .before = "%bounded = and i64 %index, 63", .index = "i64 %bounded", .reserved = true },
        .{ .before = "%bounded = and i64 %index, 127", .index = "i64 %bounded", .reserved = false },
    };
    for (cases) |case| {
        const text = try std.fmt.allocPrint(a, "{s}\ndefine i32 @read(i64 %index) {{\nentry:\n {s}\n %p = getelementptr {s}, ptr @table, {s}\n %v = load i16, ptr %p, align 2\n %wide = zext i16 %v to i32\n ret i32 %wide\n}}\n", .{ storage, case.before, case.source, case.index });
        defer a.free(text);
        var module = try ir.Module.parse(a, text);
        defer module.deinit();
        try module.verify();
        const ctx = context(&module);
        const function = module.functions.items[0];
        var arena = std.heap.ArenaAllocator.init(a);
        defer arena.deinit();
        const view = try pointers.legalize(arena.allocator(), function, &ctx);
        try std.testing.expectEqual(case.reserved, view == null);
        if (view) |legalized| {
            for (legalized.blocks.items[0].instructions.items) |inst| {
                if (inst.result != null and std.mem.eql(u8, inst.result.?, "%p")) {
                    try std.testing.expect(inst.kind.gep.ptr == .named);
                    try std.testing.expect(!std.mem.startsWith(u8, inst.kind.gep.ptr.named, "@"));
                }
            }
        }
        // Full selection still admits the generic cases, including an ordinary
        // parameter index. Strict table admission is a separate ownership gate.
        var selected = try compilation.select(a, module.target_triple.?, function, .{ .generic_cfg_selector = true, .module_context = &ctx });
        defer selected.deinit(a);
        try module.verify();
    }
}

fn checkLocalTables(object: []const u8, visibility: u8) !void {
    const shoff: usize = @intCast(std.mem.readInt(u64, object[40..48], .little));
    const count = std.mem.readInt(u16, object[60..62], .little);
    var found: usize = 0;
    for (0..count) |section| {
        const header = object[shoff + section * 64 ..][0..64];
        if (std.mem.readInt(u32, header[4..8], .little) != 2) continue;
        const start: usize = @intCast(std.mem.readInt(u64, header[24..32], .little));
        const size: usize = @intCast(std.mem.readInt(u64, header[32..40], .little));
        const strings = object[shoff + std.mem.readInt(u32, header[40..44], .little) * 64 ..][0..64];
        const strtab: usize = @intCast(std.mem.readInt(u64, strings[24..32], .little));
        for (0..size / 24) |index| {
            const symbol = object[start + index * 24 ..][0..24];
            const offset = std.mem.readInt(u32, symbol[0..4], .little);
            const name = std.mem.sliceTo(object[strtab + offset ..], 0);
            if (!std.mem.eql(u8, name, "table") and !std.mem.eql(u8, name, "unused")) continue;
            found += 1;
            try std.testing.expectEqual(@as(u8, 1), symbol[4]); // STB_LOCAL | STT_OBJECT
            try std.testing.expectEqual(visibility, symbol[5]);
            try std.testing.expect(index < std.mem.readInt(u32, header[44..48], .little));
            try std.testing.expectEqual(@as(u64, 128), std.mem.readInt(u64, symbol[16..24], .little));
            const section_index = std.mem.readInt(u16, symbol[6..8], .little);
            try std.testing.expect(section_index > 0 and section_index < count);
            const placed = object[shoff + section_index * 64 ..][0..64];
            try std.testing.expect(std.mem.readInt(u64, placed[48..56], .little) >= 64);
            try std.testing.expectEqual(@as(u64, 0), std.mem.readInt(u64, symbol[8..16], .little) % 64);
        }
    }
    try std.testing.expectEqual(@as(usize, 2), found);
}

test "constant table unsupported consumers retain full selector fallback" {
    const a = std.testing.allocator;
    const storage = try tableText(native_layout, 64, "i16", "7", "align 2");
    defer a.free(storage);
    for ([_][]const u8{
        // The reported valid read spans two adjacent i16 elements.
        "%v = load i32, ptr %p, align 2\n ret i32 %v",
        // Every use must be admitted, even when a supported load comes first.
        "%n = load i16, ptr %p, align 2\n %w = zext i16 %n to i32\n %v = load i32, ptr %p, align 2\n %sum = add i32 %w, %v\n ret i32 %sum",
        // A derived pointer must not keep an unsupported consumer trapped.
        "%q = getelementptr i8, ptr %p, i64 2\n %v = load i32, ptr %q, align 2\n ret i32 %v",
    }) |body| {
        const text = try std.fmt.allocPrint(a, "{s}\ndefine i32 @read(i64 %index) {{\nentry:\n %bounded = and i64 %index, 31\n %p = getelementptr [2 x i8], ptr @table, i64 %bounded\n {s}\n}}\n", .{ storage, body });
        defer a.free(text);
        var module = try ir.Module.parse(a, text);
        defer module.deinit();
        try module.verify();
        const ctx = context(&module);
        const function = module.functions.items[0];
        // Exercise the complete production selector, not only strict table
        // lowering or the private pointer-rewrite helper.
        var selected = try compilation.select(a, module.target_triple.?, function, .{ .generic_cfg_selector = true, .module_context = &ctx });
        defer selected.deinit(a);
        try @import("../codegen/x86_64/verify.zig").verifyFunction(selected);
        var ordinary_address = false;
        for (selected.instructions.items) |instruction| {
            try std.testing.expect(instruction != .lea_global_arg64);
            if (instruction == .lea_global_offset_rax) ordinary_address = true;
        }
        try std.testing.expect(ordinary_address);
        const object = try elf.buildObjectWithModuleContext(a, &.{selected}, &.{}, ctx);
        defer a.free(object);
        try std.testing.expectEqualSlices(u8, "\x7fELF", object[0..4]);
        try module.verify();
    }
}

test "constant table shared access contract preserves attributes widths and derived bounds" {
    var load: ir.LoadInst = .{ .ty = .{ .int = 16 }, .ptr = .{ .named = "p" } };
    const integer = tables.Description.init(.i16, 64, false).?;
    try std.testing.expect(integer.allowsLoadInst(0, load));
    load.attrs.is_volatile = true;
    try std.testing.expect(integer.allowsLoadInst(0, load));
    load.attrs.atomic_ordering = "monotonic";
    try std.testing.expect(!integer.allowsLoadInst(0, load));
    load.attrs = .{ .syncscope = "singlethread" };
    try std.testing.expect(!integer.allowsLoadInst(0, load));
    load.attrs = .{};
    load.ptr_addrspace = "addrspace(1)";
    try std.testing.expect(!integer.allowsLoadInst(0, load));
    load.ptr_addrspace = null;
    load.ty_addrspace = "addrspace(1)";
    try std.testing.expect(!integer.allowsLoadInst(0, load));
    load.ty_addrspace = null;
    load.ty = .{ .int = 32 };
    try std.testing.expect(!integer.allowsLoadInst(0, load));
    try std.testing.expect(integer.derivedOffset(0, 8) == null);
    load.ty = .double;
    for ([_]tables.Description{ tables.Description.f64_16, tables.Description.f64_512_pairs, tables.Description.f64_pair_128 }) |shape| {
        try std.testing.expect(shape.allowsLoadInst(0, load));
        const tail: ?u8 = if (shape.eql(tables.Description.f64_16)) null else 8;
        try std.testing.expectEqual(tail, shape.derivedOffset(0, 8));
        try std.testing.expectEqual(tail != null, shape.allowsLoadInst(8, load));
        try std.testing.expect(shape.derivedOffset(8, 8) == null);
        try std.testing.expect(shape.derivedOffset(0, 4) == null);
        try std.testing.expect(shape.derivedOffset(0, -8) == null);
    }
}

test "constant table removed and opaque consumers preserve complete selector routes" {
    const a = std.testing.allocator;
    const storage = try tableText(native_layout, 64, "i16", "7", "align 2");
    defer a.free(storage);
    for ([_]bool{ false, true }) |has_opaque| {
        const extra = if (has_opaque)
            "%tag = add i64 ptrtoint (ptr @table to i64), 0\n %bit = and i64 %tag, 1\n %low = trunc i64 %bit to i32"
        else
            "%dead = load i32, ptr %p, align 2";
        const tail = if (has_opaque) "%sum = add i32 %wide, %low\n ret i32 %sum" else "ret i32 %wide";
        const text = try std.fmt.allocPrint(a, "{s}\ndefine i32 @read(i64 %index) {{\nentry:\n %bounded = and i64 %index, 31\n %p = getelementptr [2 x i8], ptr @table, i64 %bounded\n {s}\n %v = load i16, ptr %p, align 2\n %wide = zext i16 %v to i32\n {s}\n}}\n", .{ storage, extra, tail });
        defer a.free(text);
        var module = try ir.Module.parse(a, text);
        defer module.deinit();
        try module.verify();
        if (!has_opaque) for (module.functions.items[0].blocks.items[0].instructions.items) |*inst| {
            if (inst.result != null and std.mem.eql(u8, inst.result.?, "dead")) inst.removed = true;
        };
        const ctx = context(&module);
        var selected = try compilation.select(a, module.target_triple.?, module.functions.items[0], .{ .generic_cfg_selector = true, .module_context = &ctx });
        defer selected.deinit(a);
        try @import("../codegen/x86_64/verify.zig").verifyFunction(selected);
        var specialized = false;
        var ordinary = false;
        for (selected.instructions.items) |inst| {
            if (inst == .lea_global_arg64) specialized = true;
            if (inst == .lea_global_offset_rax) ordinary = true;
        }
        try std.testing.expectEqual(!has_opaque, specialized);
        try std.testing.expectEqual(has_opaque, ordinary);
        const object = try elf.buildObjectWithModuleContext(a, &.{selected}, &.{}, ctx);
        defer a.free(object);
        try std.testing.expectEqualSlices(u8, "\x7fELF", object[0..4]);
        try module.verify();
    }
}

test "constant table independent objects keep private and internal storage local through ordinary placement" {
    const a = std.testing.allocator;
    // Identical private names in independently emitted modules must never
    // become global definitions. Include an unreferenced table as well.
    for ([_][]const u8{ "private", "internal hidden" }) |linkage| {
        const storage = try tableText(native_layout, 64, "i16", "7", "align 64");
        defer a.free(storage);
        const linked = try std.mem.replaceOwned(u8, a, storage, "private", linkage);
        defer a.free(linked);
        const unused = try std.mem.replaceOwned(u8, a, linked, "@table", "@unused");
        defer a.free(unused);
        const unused_global = unused[std.mem.indexOf(u8, unused, "@unused").?..];
        const text = try std.fmt.allocPrint(a, "{s}{s}\ndefine i32 @read(i64 %index) {{\nentry:\n %bounded = and i64 %index, 63\n %p = getelementptr [2 x i8], ptr @table, i64 %bounded\n %v = load i16, ptr %p, align 2\n %wide = zext i16 %v to i32\n ret i32 %wide\n}}\n", .{ linked, unused_global });
        defer a.free(text);
        var module = try ir.Module.parse(a, text);
        defer module.deinit();
        try module.verify();
        var ctx = context(&module);
        var selected = try compilation.select(a, module.target_triple.?, module.functions.items[0], .{ .generic_cfg_selector = true, .module_context = &ctx });
        defer selected.deinit(a);
        var specialized = false;
        for (selected.instructions.items) |instruction| if (instruction == .lea_global_arg64) {
            specialized = true;
        };
        try std.testing.expect(specialized);
        for ([_]bool{ false, true }) |emit_all| {
            ctx.emit_all_globals = emit_all;
            const object = try elf.buildObjectWithModuleContext(a, &.{selected}, &.{}, ctx);
            defer a.free(object);
            try checkLocalTables(object, if (std.mem.eql(u8, linkage, "private")) 0 else 2);
        }
    }
}
