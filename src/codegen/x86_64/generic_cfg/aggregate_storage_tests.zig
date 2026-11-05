const std = @import("std");
const ir = @import("../../../ir.zig");
const machine = @import("../machine.zig");
const selector = @import("../generic_cfg_selector.zig");
const verify = @import("../verify.zig");
const encoding = @import("../../../mc/encoding.zig");
const storage = @import("storage_layout.zig");
const frame = @import("padded_frame.zig");
const values = @import("word_pair_values.zig");

test "aggregate storage layouts include nested packed fields and reject incomplete definitions" {
    const names = [_]ir.NamedTypeDefinition{
        .{ .name = "File", .body = "{ i32, { i8 }, [3 x i8] }", .raw = "" },
        .{ .name = "Io", .body = "{ ptr, ptr }", .raw = "" },
        .{ .name = "Stack", .body = "{ ptr, i32, [4 x i8], i64 }", .raw = "" },
        .{ .name = "Union", .body = "{ <{ { i64, i16, [6 x i8] }, [16 x i8] }>, i8, [7 x i8] }", .raw = "" },
        .{ .name = "Cycle", .body = "{ %Cycle }", .raw = "" },
        .{ .name = "Duplicate", .body = "{ ptr, ptr }", .raw = "" },
        .{ .name = "\"Duplicate\"", .body = "{ i64 }", .raw = "" },
    };
    var context: machine.ReadOnlyModuleContext = .{ .globals = &.{}, .named_types = &names, .target_datalayout = null };
    const cases = [_]struct { text: []const u8, bytes: u32, alignment: u32 }{
        .{ .text = "%File", .bytes = 8, .alignment = 4 },
        .{ .text = "%Io", .bytes = 16, .alignment = 8 },
        .{ .text = "%Stack", .bytes = 24, .alignment = 8 },
        .{ .text = "%Union", .bytes = 40, .alignment = 1 },
        .{ .text = "{ %Union, i16, [6 x i8] }", .bytes = 48, .alignment = 2 },
        .{ .text = "<{ i8, i32, i8 }>", .bytes = 6, .alignment = 1 },
        .{ .text = "[3 x { i8, i32 }]", .bytes = 24, .alignment = 4 },
        .{ .text = "{ i8, [2 x i24] }", .bytes = 12, .alignment = 4 },
        .{ .text = "[32 x i64]", .bytes = 256, .alignment = 8 },
        .{ .text = "[8192 x i64]", .bytes = 65536, .alignment = 8 },
        .{ .text = "[0 x i8]", .bytes = 0, .alignment = 1 },
        .{ .text = "{ double }", .bytes = 8, .alignment = 8 },
        .{ .text = "{ i8, x86_fp80 }", .bytes = 32, .alignment = 16 },
        .{ .text = "<{ i8, half, float, double, fp128 }>", .bytes = 31, .alignment = 1 },
    };
    for (cases) |case| try std.testing.expectEqualDeep(storage.Layout{ .bytes = case.bytes, .alignment = case.alignment }, storage.query(&context, .{ .aggregate = case.text }).?);
    for ([_][]const u8{ "%Cycle", "%Duplicate", "%Missing", "{ i64, %Missing }", "{ i64, }", "{ i64 } junk", "{ i64", "[8193 x i64]", "[4294967295 x i128]", "<{ i8, ptr addrspace(1) }>", "{ <2 x i64> }" }) |text|
        try std.testing.expect(storage.query(&context, .{ .aggregate = text }) == null);
    context.target_datalayout = "e-a:64";
    try std.testing.expectEqualDeep(storage.Layout{ .bytes = 8, .alignment = 8 }, storage.query(&context, .{ .aggregate = "{ i8 }" }).?);
    try std.testing.expectEqualDeep(storage.Layout{ .bytes = 1, .alignment = 1 }, storage.query(&context, .{ .aggregate = "<{ i8 }>" }).?);
    for ([_][]const u8{ "e-f32:64", "e-f80:64", "e-f64:64:32", "e-f16:16:24", "e-a:4" }) |layout| {
        context.target_datalayout = layout;
        try std.testing.expect(storage.query(&context, .{ .aggregate = "{ float, double }" }) == null);
    }
    context.target_datalayout = "e-f80:128-f128:128:128";
    try std.testing.expectEqualDeep(storage.Layout{ .bytes = 32, .alignment = 16 }, storage.query(&context, .{ .aggregate = "{ x86_fp80, fp128 }" }).?);
}

test "bounded storage executes narrow odd and large objects without changing adjacent values" {
    const cases = [_]struct { ty: []const u8, bytes: u32 }{
        .{ .ty = "i16", .bytes = 2 },
        .{ .ty = "i32", .bytes = 4 },
        .{ .ty = "[1 x i8]", .bytes = 1 },
        .{ .ty = "[2 x i8]", .bytes = 2 },
        .{ .ty = "[3 x i8]", .bytes = 3 },
        .{ .ty = "[5 x i8]", .bytes = 5 },
        .{ .ty = "{ <{ i8, float, double }> }", .bytes = 13 },
        .{ .ty = "[4000 x i8]", .bytes = 4000 },
        .{ .ty = "[4096 x i8]", .bytes = 4096 },
        .{ .ty = "[8193 x i8]", .bytes = 8193 },
        .{ .ty = "[65536 x i8]", .bytes = 65536 },
    };
    for (cases) |case| {
        const text = try std.fmt.allocPrint(std.testing.allocator,
            \\define i64 @object_{d}(i64 %a, i64 %b) {{
            \\entry:
            \\  %slot = alloca {s}, align 8
            \\  %guard = alloca [8 x i8], align 8
            \\  %tail = getelementptr i8, ptr %slot, i64 {d}
            \\  %first = trunc i64 %a to i8
            \\  %last = trunc i64 %b to i8
            \\  store i64 %a, ptr %guard
            \\  store i8 %first, ptr %slot
            \\  store i8 %last, ptr %tail
            \\  %x = load i8, ptr %slot
            \\  %y = load i8, ptr %tail
            \\  %saved = load i64, ptr %guard
            \\  %left = zext i8 %x to i64
            \\  %right = zext i8 %y to i64
            \\  %live = xor i64 %saved, %b
            \\  %sum = add i64 %live, %left
            \\  %result = xor i64 %sum, %right
            \\  ret i64 %result
            \\}}
        , .{ case.bytes, case.ty, case.bytes - 1 });
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        const code = try executable(module);
        defer std.posix.munmap(code);
        const run: *const fn (u64, u64) callconv(.c) u64 = @ptrCast(code.ptr);
        const inputs = [_]u64{ 0, 1, 0xdeadbeef01234567, 0x80000000000000ff, std.math.maxInt(u64) };
        for (inputs) |a| for (inputs) |b|
            try std.testing.expectEqual(((a ^ b) +% (if (case.bytes == 1) b & 255 else a & 255)) ^ (b & 255), run(a, b));
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        const view = (try frame.legalizeStorage(arena.allocator(), module.functions.items[0], null)).?;
        try std.testing.expect(try frame.legalizeStorage(arena.allocator(), view, null) == null);
        try module.verify();
    }
}

test "bounded storage copy extents exclude carrier padding and zero sized objects" {
    for ([_]u32{ 0, 1, 2, 3, 5 }) |bytes| {
        const text = try std.fmt.allocPrint(std.testing.allocator, "declare void @llvm.memcpy.p0.p0.i64(ptr, ptr, i64, i1)\ndefine void @copy(ptr %out) {{\nentry:\n  %slot = alloca [{d} x i8], align 1\n  call void @llvm.memcpy.p0.p0.i64(ptr %out, ptr %slot, i64 {d}, i1 false)\n  ret void\n}}\n", .{ bytes, bytes });
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        const function = &module.functions.items[0];
        try std.testing.expect(try frame.legalizeStorage(arena.allocator(), function.*, null) != null);
        function.blocks.items[0].instructions.items[1].kind.call.args.items[2].value = .{ .int = bytes + 1 };
        try std.testing.expect(try frame.legalizeStorage(arena.allocator(), function.*, null) == null);
    }
}

test "bounded storage rejects huge frame arithmetic and unsupported stack alignment" {
    const helpers = @import("composed_helpers.zig");
    try std.testing.expect(helpers.alignedCallFrameBytes(std.math.maxInt(u32)) == null);
    try std.testing.expect(helpers.alignedCallFrameBytes(std.math.maxInt(u32) - 7) == null);
    for ([_][]const u8{
        "[262144 x i32], align 4", "[1073741823 x i32], align 4", "[4294967295 x i32], align 4", "i64, align 32", "[1 x i32], align 2147483648",
    }) |allocation| {
        const text = try std.fmt.allocPrint(std.testing.allocator, "define i32 @large() {{\nentry:\n  %slot = alloca {s}\n  store i32 7, ptr %slot\n  ret i32 7\n}}\n", .{allocation});
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        var output = machine.MachineFunction.init("large", .{ .int = 32 });
        defer output.deinit(std.testing.allocator);
        const result = try selector.tryLower(std.testing.allocator, &output, module.functions.items[0]);
        try std.testing.expect(result == .unsupported);
        try std.testing.expectEqual(@as(usize, 0), output.instructions.items.len);
    }
}

fn executable(module: ir.Module) ![]align(std.heap.page_size_min) u8 {
    const function = module.functions.items[0];
    const context: machine.ReadOnlyModuleContext = .{ .globals = module.globals.items, .named_types = module.named_types.items, .target_datalayout = module.target_datalayout };
    var output = machine.MachineFunction.init(function.name, function.ret_ty);
    defer output.deinit(std.testing.allocator);
    const selected = try selector.tryLowerWithContext(std.testing.allocator, &output, function, &context);
    if (selected == .unsupported) std.debug.print("aggregate storage {s}: {s}\n", .{ function.name, selected.unsupported.detail() });
    try std.testing.expectEqual(selector.SelectionResult.selected, selected);
    try verify.verifyFunction(output);
    try std.testing.expect(output.selection_owner == .composed_block or output.selection_owner == .composed_cfg);
    const code = try encoding.encodeFunction(std.testing.allocator, output);
    defer std.testing.allocator.free(code);
    const memory = try std.posix.mmap(null, code.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    @memcpy(memory[0..code.len], code);
    return memory;
}

test "aggregate storage executes independent nested stack objects at their exact boundaries" {
    const text =
        \\%Record = type { <{ { i64, i16, [6 x i8] }, [16 x i8] }>, i8, [7 x i8] }
        \\define i64 @storage(i64 %a, i64 %b) {
        \\entry:
        \\  %first = alloca { %Record, i16, [6 x i8] }, align 8
        \\  %second = alloca { ptr, i32, [4 x i8], i64 }, align 8
        \\  %last = getelementptr i8, ptr %first, i64 40
        \\  %tail = getelementptr i8, ptr %second, i64 16
        \\  store i64 %a, ptr %first
        \\  store i64 %b, ptr %last
        \\  store i64 55, ptr %tail
        \\  %x = load i64, ptr %first
        \\  %y = load i64, ptr %last
        \\  %z = load i64, ptr %tail
        \\  %xy = xor i64 %x, %y
        \\  %result = add i64 %xy, %z
        \\  ret i64 %result
        \\}
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();
    try module.verify();
    const code = try executable(module);
    defer std.posix.munmap(code);
    const run: *const fn (u64, u64) callconv(.c) u64 = @ptrCast(code.ptr);
    const inputs = [_]u64{ 0, 1, 0xdeadbeefcafe0123, 0x8000000000000000, std.math.maxInt(u64) };
    for (inputs) |a| for (inputs) |b| try std.testing.expectEqual((a ^ b) +% 55, run(a, b));
    const context: machine.ReadOnlyModuleContext = .{ .globals = module.globals.items, .named_types = module.named_types.items, .target_datalayout = null };
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const view = (try frame.legalizeStorage(arena.allocator(), module.functions.items[0], &context)).?;
    try std.testing.expect(try frame.legalizeStorage(arena.allocator(), view, &context) == null);
    try std.testing.expectEqualStrings("{ %Record, i16, [6 x i8] }", module.functions.items[0].blocks.items[0].instructions.items[0].kind.alloca.allocated_ty.aggregate);
    try module.verify();
}

test "aggregate storage pair loads constructors and stores preserve source independence and guards" {
    const text =
        \\define i64 @pair(ptr %source, ptr %destination, i64 %extra) {
        \\entry:
        \\  %original = load { ptr, i64 }, ptr %source, align 8
        \\  %pointer = extractvalue { ptr, i64 } %original, 0
        \\  %length = extractvalue { ptr, i64 } %original, 1
        \\  %increased = add i64 %length, %extra
        \\  %replaced = insertvalue { ptr, i64 } %original, i64 %increased, 1
        \\  store { ptr, i64 } %replaced, ptr %destination, align 8
        \\  ret i64 %length
        \\}
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();
    try module.verify();
    const code = try executable(module);
    defer std.posix.munmap(code);
    const run: *const fn (*const [2]u64, *[2]u64, u64) callconv(.c) u64 = @ptrCast(code.ptr);
    const inputs = [_]u64{ 0, 1, 0xdeadbeefcafe0123, 0x8000000000000000, std.math.maxInt(u64) };
    for (inputs) |pointer| for (inputs) |length| for (inputs) |extra| {
        const source = [2]u64{ pointer, length };
        var destination = [4]u64{ 0xf00d, 0, 0, 0xbeef };
        try std.testing.expectEqual(length, run(&source, destination[1..3], extra));
        try std.testing.expectEqualSlices(u64, &.{ 0xf00d, pointer, length +% extra, 0xbeef }, &destination);
        try std.testing.expectEqualSlices(u64, &.{ pointer, length }, &source);
    };
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const view = (try values.legalize(arena.allocator(), module.functions.items[0], null)).?;
    try std.testing.expect(try values.legalize(arena.allocator(), view, null) == null);
    try module.verify();
}

test "aggregate storage rejects unsafe allocation and copy forms without mutating inputs" {
    const text =
        \\declare void @llvm.memcpy.p0.p0.i64(ptr, ptr, i64, i1)
        \\define void @storage(ptr %output, i64 %size) {
        \\entry:
        \\  %slot = alloca { [6 x i64] }, align 8
        \\  store i64 55, ptr %slot
        \\  call void @llvm.memcpy.p0.p0.i64(ptr %output, ptr %slot, i64 48, i1 false)
        \\  ret void
        \\}
    ;
    for (0..10) |boundary| {
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        const function = &module.functions.items[0];
        const insts = function.blocks.items[0].instructions.items;
        switch (boundary) {
            0 => insts[0].kind.alloca.count = .{ .ty = .{ .int = 64 }, .value = .{ .int = 2 } },
            1 => insts[0].kind.alloca.count = .{ .ty = .{ .int = 64 }, .value = .{ .named = "size" } },
            2 => insts[0].kind.alloca.attrs = "align 32",
            3 => insts[0].kind.alloca.attrs = "align 8, inalloca",
            4 => insts[0].kind.alloca.allocated_ty_addrspace = "1",
            5 => insts[1].kind.store.attrs.is_volatile = true,
            6 => insts[1].kind.store.ptr_addrspace = "1",
            7 => insts[2].kind.call.args.items[2].value = .{ .int = 49 },
            8 => insts[2].kind.call.args.items[2].value = .{ .int = -1 },
            9 => insts[2].kind.call.args.items[2].value = .{ .named = "size" },
            else => unreachable,
        }
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        try std.testing.expect(try frame.legalizeStorage(arena.allocator(), function.*, null) == null);
        try std.testing.expectEqualStrings("{ [6 x i64] }", insts[0].kind.alloca.allocated_ty.aggregate);
        try std.testing.expectEqualStrings("slot", insts[2].kind.call.args.items[1].value.named);
    }
}

test "aggregate storage pair legalization rejects barriers unsupported ABI and unresolved leaves" {
    const cases = [_][]const u8{
        "define { ptr, i64 } @f(ptr %p) {\nentry:\n  %v = load volatile { ptr, i64 }, ptr %p\n  ret { ptr, i64 } %v\n}\n",
        "define void @f(ptr %p) {\nentry:\n  %v = insertvalue { ptr, i64 } poison, i64 1, 1\n  store volatile { ptr, i64 } %v, ptr %p\n  ret void\n}\n",
        "define { ptr, i64 } @f({ ptr, i64 } %p) {\nentry:\n  ret { ptr, i64 } %p\n}\n",
        "declare coldcc { ptr, i64 } @callee()\ndefine i64 @f() {\nentry:\n  %v = call coldcc { ptr, i64 } @callee()\n  %x = extractvalue { ptr, i64 } %v, 1\n  ret i64 %x\n}\n",
        "define i64 @f(ptr %callee) {\nentry:\n  %v = call coldcc { ptr, i64 } %callee()\n  %x = extractvalue { ptr, i64 } %v, 1\n  ret i64 %x\n}\n",
        "define i64 @f() {\nentry:\n  %v = extractvalue { ptr, i64 } { i64 1, i64 2 }, 1\n  ret i64 %v\n}\n",
    };
    for (cases) |text| {
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        try std.testing.expect(try values.legalize(arena.allocator(), module.functions.items[0], null) == null);
    }
}
