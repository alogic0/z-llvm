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
        .{ .text = "{ <2 x i64> }", .bytes = 16, .alignment = 16 },
        .{ .text = "[4 x <4 x i32>]", .bytes = 64, .alignment = 16 },
        .{ .text = "[8192 x i64]", .bytes = 65536, .alignment = 8 },
        .{ .text = "[0 x i8]", .bytes = 0, .alignment = 1 },
        .{ .text = "{ double }", .bytes = 8, .alignment = 8 },
        .{ .text = "{ i8, x86_fp80 }", .bytes = 32, .alignment = 16 },
        .{ .text = "<{ i8, half, float, double, fp128 }>", .bytes = 31, .alignment = 1 },
    };
    for (cases) |case| try std.testing.expectEqualDeep(storage.Layout{ .bytes = case.bytes, .alignment = case.alignment }, storage.query(&context, .{ .aggregate = case.text }).?);
    for ([_][]const u8{ "%Cycle", "%Duplicate", "%Missing", "{ i64, %Missing }", "{ i64, }", "{ i64 } junk", "{ i64", "[8193 x i64]", "[4294967295 x i128]", "<{ i8, ptr addrspace(1) }>", "{ <4 x i64> }" }) |text|
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
    context.target_datalayout = "e-v128:64";
    try std.testing.expect(storage.query(&context, .{ .aggregate = "[4 x <4 x i32>]" }) == null);
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

test "bounded storage runtime copies preserve exact bytes and source call ownership" {
    var module = try ir.Module.parse(std.testing.allocator,
        \\declare void @llvm.memcpy.p0.p0.i64(ptr, ptr, i64, i1)
        \\declare void @llvm.memset.p0.i64(ptr, i8, i64, i1)
        \\define i64 @runtime_copy(ptr %input, ptr %output, i64 %length, i64 %live) {
        \\entry:
        \\ %slot = alloca [33 x i8], align 8
        \\ call void @llvm.memset.p0.i64(ptr %slot, i8 -91, i64 33, i1 false)
        \\ call void @llvm.memcpy.p0.p0.i64(ptr %slot, ptr %input, i64 %length, i1 false)
        \\ call void @llvm.memcpy.p0.p0.i64(ptr %output, ptr %slot, i64 33, i1 false)
        \\ ret i64 %live
        \\}
    );
    defer module.deinit();
    try module.verify();
    const original = module.functions.items[0];
    const source_copy = original.blocks.items[0].instructions.items[2].kind.call;
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const view = (try frame.legalizeStorage(arena.allocator(), original, null)).?;
    try std.testing.expectEqual(original.params.items.ptr, view.params.items.ptr);
    try std.testing.expect(original.ret_ty.eql(view.ret_ty));
    var found_runtime_copy = false;
    for (view.blocks.items[0].instructions.items) |inst| {
        if (inst.kind != .call or inst.kind.call.args.items.len != 4 or
            !inst.kind.call.args.items[2].value.eql(.{ .named = "length" })) continue;
        found_runtime_copy = true;
        try std.testing.expect(inst.kind.call.args.items.ptr != source_copy.args.items.ptr);
        try std.testing.expect(!inst.kind.call.args.items[0].value.eql(source_copy.args.items[0].value));
        try std.testing.expectEqualDeep(source_copy.args.items[1..], inst.kind.call.args.items[1..]);
    }
    try std.testing.expect(found_runtime_copy);
    try std.testing.expectEqualStrings("slot", source_copy.args.items[0].value.named);
    try std.testing.expect(try frame.legalizeStorage(arena.allocator(), view, null) == null);
    var private = module;
    private.functions = try module.functions.clone(arena.allocator());
    private.functions.items[0] = view;
    try private.verify();
    try module.verify();

    const code = try executable(module);
    defer std.posix.munmap(code);
    const run: *const fn ([*]const u8, [*]u8, u64, u64) callconv(.c) u64 = @ptrCast(code.ptr);
    var input: [33]u8 = undefined;
    for (&input, 0..) |*byte, i| byte.* = @truncate(i * 17 + 3);
    for (0..34) |length| {
        var actual: [49]u8 = @splat(0x5a);
        var expected = actual;
        @memset(expected[8..41], 0xa5);
        @memcpy(expected[8..][0..length], input[0..length]);
        const live = @as(u64, 0xf0e1d2c3b4a59687) +% length;
        try std.testing.expectEqual(live, run(&input, actual[8..].ptr, length, live));
        try std.testing.expectEqualSlices(u8, &expected, &actual);
    }
}

test "bounded storage runtime copy admission retains specialized and inline limits" {
    for ([_][]const u8{ "llvm.memcpy.p0.p0.i64", "llvm.memcpy.inline.p0.p0.i64" }) |callee| {
        const source = try std.fmt.allocPrint(
            std.testing.allocator,
            "declare void @{s}(ptr, ptr, i64, i1)\ndefine void @copy(ptr %output, i64 %length) {{\nentry:\n %slot = alloca {{ i64, i16, [6 x i8] }}, align 8\n call void @{s}(ptr %output, ptr %slot, i64 %length, i1 false)\n ret void\n}}\n",
            .{ callee, callee },
        );
        defer std.testing.allocator.free(source);
        var module = try ir.Module.parse(std.testing.allocator, source);
        defer module.deinit();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        const function = module.functions.items[0];
        try std.testing.expect(try frame.legalize(arena.allocator(), function, null) == null);
        const view = try frame.legalizeStorage(arena.allocator(), function, null);
        try std.testing.expectEqual(!std.mem.eql(u8, callee, "llvm.memcpy.inline.p0.p0.i64"), view != null);
    }
}

test "bounded storage rejects huge frame arithmetic and unsupported stack alignment" {
    const helpers = @import("composed_helpers.zig");
    try std.testing.expect(helpers.alignedCallFrameBytes(std.math.maxInt(u32)) == null);
    try std.testing.expect(helpers.alignedCallFrameBytes(std.math.maxInt(u32) - 7) == null);
    for ([_][]const u8{
        "[2097152 x i32], align 4", "[1073741823 x i32], align 4", "[4294967295 x i32], align 4", "i64, align 8192", "[1 x i32], align 2147483648",
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
    for (0..9) |boundary| {
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

test "stack address values execute pointer PHIs and selected stack data" {
    const text =
        \\define i64 @choose(i64 %a, i64 %b) {
        \\entry:
        \\  %left = alloca [3 x i64], align 8
        \\  %right = alloca [3 x i64], align 8
        \\  store i64 %a, ptr %left
        \\  store i64 %b, ptr %right
        \\  %choose = icmp ne i64 %b, 0
        \\  br i1 %choose, label %yes, label %no
        \\yes:
        \\  br label %merge
        \\no:
        \\  br label %merge
        \\merge:
        \\  %selected = phi ptr [ %left, %yes ], [ %right, %no ]
        \\  %value = load i64, ptr %selected
        \\  %live = xor i64 %a, %b
        \\  %result = add i64 %value, %live
        \\  ret i64 %result
        \\}
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();
    try module.verify();
    const code = try executable(module);
    defer std.posix.munmap(code);
    const run: *const fn (u64, u64) callconv(.c) u64 = @ptrCast(code.ptr);
    const inputs = [_]u64{ 0, 1, 0x8000000000000000, std.math.maxInt(u64) };
    for (inputs) |a| for (inputs) |b| try std.testing.expectEqual((if (b != 0) a else b) +% (a ^ b), run(a, b));
}

test "stack address values execute loop carried frame addresses and index arithmetic" {
    const text =
        \\define i64 @loop(i64 %a) {
        \\entry:
        \\  %slot = alloca [4 x i64], align 8
        \\  br label %loop
        \\loop:
        \\  %cursor = phi ptr [ %slot, %entry ], [ %next, %loop ]
        \\  %index = phi i64 [ 0, %entry ], [ %increment, %loop ]
        \\  %value = add i64 %a, %index
        \\  store i64 %value, ptr %cursor
        \\  %next = getelementptr i8, ptr %cursor, i64 8
        \\  %increment = add i64 %index, 1
        \\  %again = icmp ult i64 %increment, 4
        \\  br i1 %again, label %loop, label %done
        \\done:
        \\  %tail = getelementptr i8, ptr %slot, i64 24
        \\  %result = load i64, ptr %tail
        \\  ret i64 %result
        \\}
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();
    try module.verify();
    const code = try executable(module);
    defer std.posix.munmap(code);
    const run: *const fn (u64) callconv(.c) u64 = @ptrCast(code.ptr);
    for ([_]u64{ 0, 1, 0x8000000000000000, std.math.maxInt(u64) }) |a| try std.testing.expectEqual(a +% 3, run(a));
}

test "stack address values preserve dynamic addresses casts and stored frame pointers" {
    const text =
        \\define i64 @address(i64 %a, i64 %b) {
        \\entry:
        \\  %slot = alloca [16 x i32], align 16
        \\  %holder = alloca ptr, align 8
        \\  %index = and i64 %b, 7
        \\  %offset = shl i64 %index, 3
        \\  %element = getelementptr i8, ptr %slot, i64 %offset
        \\  store i64 %a, ptr %element
        \\  store ptr %slot, ptr %holder
        \\  %pointer = load ptr, ptr %holder
        \\  %bits = ptrtoint ptr %slot to i64
        \\  %roundtrip = inttoptr i64 %bits to ptr
        \\  %same = icmp eq ptr %pointer, %roundtrip
        \\  %wide = zext i1 %same to i64
        \\  %loaded = load i64, ptr %element
        \\  %result = xor i64 %loaded, %wide
        \\  ret i64 %result
        \\}
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();
    try module.verify();
    const code = try executable(module);
    defer std.posix.munmap(code);
    const run: *const fn (u64, u64) callconv(.c) u64 = @ptrCast(code.ptr);
    const inputs = [_]u64{ 0, 1, 7, 8, 0x8000000000000000, std.math.maxInt(u64) };
    for (inputs) |a| for (inputs) |b| try std.testing.expectEqual(a ^ 1, run(a, b));
    const addresses = @import("stack_addresses.zig");
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const view = (try addresses.legalize(arena.allocator(), module.functions.items[0], null)).?;
    try std.testing.expect(try addresses.legalize(arena.allocator(), view, null) == null);
    var private_module = module;
    private_module.functions = try module.functions.clone(arena.allocator());
    private_module.functions.items[0] = view;
    try private_module.verify();
    try std.testing.expectEqualStrings("slot", module.functions.items[0].blocks.items[0].instructions.items[0].result.?);
    try module.verify();
}

test "stack address values retain allocation admission and reject unsupported layouts" {
    const addresses = @import("stack_addresses.zig");
    const text = "define i64 @address() {\nentry:\n  %slot = alloca [4 x i32], align 8\n  %address = ptrtoint ptr %slot to i64\n  ret i64 %address\n}\n";
    for (0..6) |boundary| {
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        const alloca = &module.functions.items[0].blocks.items[0].instructions.items[0].kind.alloca;
        var context: machine.ReadOnlyModuleContext = .{ .globals = &.{}, .named_types = &.{}, .target_datalayout = null };
        switch (boundary) {
            0 => alloca.attrs = "align 32",
            1 => alloca.attrs = "align 8, inalloca",
            2 => alloca.count = .{ .ty = .{ .int = 64 }, .value = .{ .int = 2 } },
            3 => alloca.allocated_ty_addrspace = "1",
            4 => alloca.allocated_ty = .{ .aggregate = "[2097153 x i32]" },
            5 => context.target_datalayout = "E-p:64:64",
            else => unreachable,
        }
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        try std.testing.expect(try addresses.legalize(arena.allocator(), module.functions.items[0], &context) == null);
        try std.testing.expectEqualStrings("slot", module.functions.items[0].blocks.items[0].instructions.items[0].result.?);
    }
}

test "large native i32 frame address views preserve source ownership and remain idempotent" {
    const addresses = @import("stack_addresses.zig");
    for ([_]u32{ 16385, 262144, 1835008 }) |words| {
        const text = try std.fmt.allocPrint(std.testing.allocator,
            \\declare void @observe(ptr)
            \\define void @large() {{
            \\entry:
            \\ %slot = alloca [{d} x i32], align 16
            \\ call void @observe(ptr %slot)
            \\ ret void
            \\}}
        , .{words});
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        const view = (try addresses.legalize(arena.allocator(), module.functions.items[0], null)).?;
        try std.testing.expect(try addresses.legalize(arena.allocator(), view, null) == null);
        try std.testing.expectEqualStrings("slot", module.functions.items[0].blocks.items[0].instructions.items[0].result.?);
        try std.testing.expectEqual(@as(usize, 2), module.functions.items[0].blocks.items[0].instructions.items.len);
        try std.testing.expectEqual(@as(usize, 3), view.blocks.items[0].instructions.items.len);
        var private_module = module;
        private_module.functions = try module.functions.clone(arena.allocator());
        private_module.functions.items[0] = view;
        try private_module.verify();
        try module.verify();
    }
}

test "large frame views keep aggregate object limits and non-native layouts closed" {
    const addresses = @import("stack_addresses.zig");
    for ([_]struct { ty: []const u8, layout: ?[]const u8 }{
        .{ .ty = "[2097153 x i32]", .layout = null },
        .{ .ty = "[2147483647 x i32]", .layout = null },
        .{ .ty = "[1048576 x i8]", .layout = null },
        .{ .ty = "{ [262144 x i32] }", .layout = null },
        .{ .ty = "[262144 x i32]", .layout = "E-p:64:64" },
        .{ .ty = "[262144 x i32]", .layout = "e-p:32:32" },
        .{ .ty = "[262144 x i32]", .layout = "e-i32:64" },
    }) |case| {
        const text = try std.fmt.allocPrint(std.testing.allocator,
            \\declare void @observe(ptr)
            \\define void @large() {{
            \\entry:
            \\ %slot = alloca {s}, align 16
            \\ call void @observe(ptr %slot)
            \\ ret void
            \\}}
        , .{case.ty});
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        const context: machine.ReadOnlyModuleContext = .{ .globals = &.{}, .named_types = &.{}, .target_datalayout = case.layout };
        try std.testing.expect(try addresses.legalize(arena.allocator(), module.functions.items[0], &context) == null);
        try module.verify();
    }
}
