const std = @import("std");
const ir = @import("../ir.zig");
const pass_manager = @import("../pass_manager.zig");
const pipelines = @import("../pipelines.zig");

fn optimize(input: []const u8, passes: []const u8) !ir.Module {
    var module = try ir.Module.parse(std.testing.allocator, input);
    errdefer module.deinit();
    try module.verify();
    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pipelines.addPasses(&pm, passes);
    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    _ = try pm.run(&module, &context, &output.writer, false);
    try module.verify();
    return module;
}

fn expectReturn(module: ir.Module, block: usize, value: i128) !void {
    const ret = module.functions.items[0].blocks.items[block].terminator.?.ret;
    try std.testing.expect(ret.value.?.eql(.{ .int = value }));
}

test "optimizer regression: early-cse restores sibling store facts after overwrite or barrier" {
    for ([_][]const u8{ "store i32 2, ptr %p", "call void @clobber(ptr %p)" }) |mutation| {
        const input = try std.fmt.allocPrint(std.testing.allocator,
            \\declare void @clobber(ptr)
            \\define i32 @f(ptr %p, i1 %cond) {{
            \\entry:
            \\  store i32 1, ptr %p
            \\  br i1 %cond, label %left, label %right
            \\left:
            \\  {s}
            \\  ret i32 2
            \\right:
            \\  %x = load i32, ptr %p
            \\  ret i32 %x
            \\}}
        , .{mutation});
        defer std.testing.allocator.free(input);
        var module = try optimize(input, "early-cse");
        defer module.deinit();
        try expectReturn(module, 2, 1);
    }
}

test "optimizer regression: early-cse does not forward stale stores into joins or loops" {
    const inputs = [_][]const u8{
        \\define i32 @f(ptr %p, i1 %cond) {
        \\entry:
        \\  store i32 1, ptr %p
        \\  br i1 %cond, label %left, label %right
        \\left:
        \\  store i32 2, ptr %p
        \\  br label %join
        \\right:
        \\  br label %join
        \\join:
        \\  %x = load i32, ptr %p
        \\  ret i32 %x
        \\}
        ,
        \\define i32 @f(ptr %p, i1 %cond) {
        \\entry:
        \\  store i32 1, ptr %p
        \\  br label %loop
        \\loop:
        \\  %x = load i32, ptr %p
        \\  store i32 2, ptr %p
        \\  br i1 %cond, label %loop, label %exit
        \\exit:
        \\  ret i32 %x
        \\}
        ,
    };
    for (inputs) |input| {
        var module = try optimize(input, "early-cse");
        defer module.deinit();
        const function = module.functions.items[0];
        const ret = function.blocks.items[function.blocks.items.len - 1].terminator.?.ret;
        try std.testing.expect(ret.value.?.eql(.{ .named = "x" }));
    }
}

test "optimizer regression: signed division and remainder normalize narrow bitpatterns" {
    var module = try optimize(
        \\define i8 @f() {
        \\entry:
        \\  %t = trunc i32 -2 to i8
        \\  %x = sdiv i8 %t, 2
        \\  ret i8 %x
        \\}
    , "instcombine");
    defer module.deinit();
    try expectReturn(module, 0, -1);

    const Case = struct { op: []const u8, bits: u16, lhs: i128, rhs: i128, expected: i128 };
    for ([_]Case{
        .{ .op = "sdiv", .bits = 8, .lhs = 254, .rhs = 2, .expected = -1 },
        .{ .op = "sdiv", .bits = 8, .lhs = 6, .rhs = 254, .expected = -3 },
        .{ .op = "srem", .bits = 8, .lhs = 253, .rhs = 2, .expected = -1 },
        .{ .op = "srem", .bits = 16, .lhs = 65531, .rhs = 65533, .expected = -2 },
        .{ .op = "sdiv exact", .bits = 8, .lhs = 250, .rhs = 2, .expected = -3 },
        .{ .op = "sdiv", .bits = 128, .lhs = std.math.minInt(i128), .rhs = 2, .expected = @divExact(std.math.minInt(i128), 2) },
    }) |case| {
        const input = try std.fmt.allocPrint(
            std.testing.allocator,
            "define i{d} @f() {{\nentry:\n  %x = {s} i{d} {d}, {d}\n  ret i{d} %x\n}}\n",
            .{ case.bits, case.op, case.bits, case.lhs, case.rhs, case.bits },
        );
        defer std.testing.allocator.free(input);
        var folded = try optimize(input, "instcombine");
        defer folded.deinit();
        try expectReturn(folded, 0, case.expected);
    }
}

test "optimizer regression: constant arithmetic wraps without host overflow" {
    const Case = struct { op: []const u8, bits: u16, lhs: i128, rhs: i128, expected: i128 };
    for ([_]Case{
        .{ .op = "mul", .bits = 128, .lhs = 1 << 64, .rhs = 1 << 64, .expected = 0 },
        .{ .op = "add", .bits = 128, .lhs = std.math.maxInt(i128), .rhs = 1, .expected = std.math.minInt(i128) },
        .{ .op = "sub", .bits = 128, .lhs = std.math.minInt(i128), .rhs = 1, .expected = std.math.maxInt(i128) },
        .{ .op = "mul", .bits = 128, .lhs = std.math.minInt(i128), .rhs = -1, .expected = std.math.minInt(i128) },
        .{ .op = "mul", .bits = 64, .lhs = std.math.maxInt(u64), .rhs = std.math.maxInt(u64), .expected = 1 },
        .{ .op = "add", .bits = 127, .lhs = (1 << 126) - 1, .rhs = 1, .expected = -(1 << 126) },
        .{ .op = "mul", .bits = 127, .lhs = 1 << 100, .rhs = 1 << 100, .expected = 0 },
    }) |case| {
        const input = try std.fmt.allocPrint(
            std.testing.allocator,
            "define i{d} @f() {{\nentry:\n  %x = {s} i{d} {d}, {d}\n  ret i{d} %x\n}}\n",
            .{ case.bits, case.op, case.bits, case.lhs, case.rhs, case.bits },
        );
        defer std.testing.allocator.free(input);
        var module = try optimize(input, "instcombine");
        defer module.deinit();
        try expectReturn(module, 0, case.expected);
    }
}

test "optimizer regression: signed division preserves undefined and inexact cases" {
    for ([_][]const u8{
        "sdiv i8 7, 0",
        "sdiv i8 128, 255",
        "srem i8 128, 255",
        "sdiv exact i8 253, 2",
        "sdiv i128 -170141183460469231731687303715884105728, -1",
        "srem i128 -170141183460469231731687303715884105728, -1",
    }) |expression| {
        const ty = if (std.mem.indexOf(u8, expression, "i128") != null) "i128" else "i8";
        const input = try std.fmt.allocPrint(
            std.testing.allocator,
            "define {s} @f() {{\nentry:\n  %x = {s}\n  ret {s} %x\n}}\n",
            .{ ty, expression, ty },
        );
        defer std.testing.allocator.free(input);
        var module = try optimize(input, "instcombine");
        defer module.deinit();
        try std.testing.expect(module.functions.items[0].blocks.items[0].terminator.?.ret.value.?.eql(.{ .named = "x" }));
    }
}

test "optimizer regression: licm keeps a returned induction update inside its loop" {
    var module = try optimize(
        \\define i32 @f(i32 %n) {
        \\entry:
        \\  br label %loop
        \\loop:
        \\  %i = phi i32 [ 0, %entry ], [ %next, %loop ]
        \\  %next = add i32 %i, 1
        \\  %done = icmp eq i32 %next, %n
        \\  br i1 %done, label %exit, label %loop
        \\exit:
        \\  ret i32 %next
        \\}
    , "licm");
    defer module.deinit();
    try std.testing.expectEqualStrings("next", module.functions.items[0].blocks.items[1].instructions.items[1].result.?);
}

test "optimizer regression: licm sinks loads before exit memory effects" {
    for ([_][]const u8{ "store i32 99, ptr %p", "call void @clobber(ptr %p)" }) |effect| {
        const input = try std.fmt.allocPrint(std.testing.allocator,
            \\declare void @clobber(ptr)
            \\define i32 @f(ptr %p, i32 %n) {{
            \\entry:
            \\  br label %loop
            \\loop:
            \\  %i = phi i32 [ 0, %entry ], [ %next, %loop ]
            \\  %q = getelementptr i32, ptr %p, i32 %i
            \\  %x = load i32, ptr %q
            \\  %next = add i32 %i, 1
            \\  %done = icmp eq i32 %next, %n
            \\  br i1 %done, label %exit, label %loop
            \\exit:
            \\  {s}
            \\  ret i32 %x
            \\}}
        , .{effect});
        defer std.testing.allocator.free(input);
        var module = try optimize(input, "licm");
        defer module.deinit();
        const exit = module.functions.items[0].blocks.items[2];
        // A positive sinking case: the load must precede the exit store/call.
        try std.testing.expect(exit.instructions.items[1].kind == .gep);
        try std.testing.expect(exit.instructions.items[2].kind == .load);
        try std.testing.expect(exit.instructions.items[3].kind == .store or exit.instructions.items[3].kind == .call);
    }
}

test "optimizer regression: licm preserves other users of sunk loads and geps" {
    for ([_][]const u8{
        "%other = icmp eq i32 %x, 0",
        "%other = icmp eq ptr %q, %p",
        "%other = insertelement <2 x i32> poison, i32 %x, i32 0",
    }) |other_use| {
        const input = try std.fmt.allocPrint(std.testing.allocator,
            \\define i32 @f(ptr %p, i32 %n) {{
            \\entry:
            \\  br label %loop
            \\loop:
            \\  %i = phi i32 [ 0, %entry ], [ %next, %loop ]
            \\  %q = getelementptr i32, ptr %p, i32 %i
            \\  %x = load i32, ptr %q
            \\  {s}
            \\  %next = add i32 %i, 1
            \\  %done = icmp eq i32 %next, %n
            \\  br i1 %done, label %exit, label %loop
            \\exit:
            \\  ret i32 %x
            \\}}
        , .{other_use});
        defer std.testing.allocator.free(input);
        var module = try optimize(input, "licm");
        defer module.deinit();
        const loop = module.functions.items[0].blocks.items[1];
        try std.testing.expect(loop.instructions.items[1].kind == .gep);
        try std.testing.expect(loop.instructions.items[2].kind == .load);
    }
}
