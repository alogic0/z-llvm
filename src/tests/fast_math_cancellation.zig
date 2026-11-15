const std = @import("std");
const ir = @import("../ir.zig");
const pm = @import("../pass_manager.zig");
const instcombine = @import("../passes/instcombine.zig");

fn combine(module: *ir.Module) !pm.PassResult {
    var context: pm.Context = .{ .allocator = std.testing.allocator };
    return instcombine.pass.run(module, &context);
}

fn liveBinaries(function: ir.Function) usize {
    var count: usize = 0;
    for (function.blocks.items) |block| for (block.instructions.items) |instruction| {
        if (!instruction.removed and instruction.kind == .binary) count += 1;
    };
    return count;
}

test "floating cancellation requires promises on both operations and preserves strict rounding" {
    const flags = [_]struct { first: []const u8, second: []const u8, folded: bool }{
        .{ .first = "fast", .second = "fast", .folded = true },
        .{ .first = "reassoc nnan ninf nsz", .second = "reassoc nnan ninf nsz", .folded = true },
        .{ .first = "", .second = "", .folded = false },
        .{ .first = "fast", .second = "", .folded = false },
        .{ .first = "", .second = "fast", .folded = false },
        .{ .first = "nnan ninf nsz", .second = "fast", .folded = false },
        .{ .first = "fast", .second = "reassoc nnan ninf", .folded = false },
        .{ .first = "reassoc ninf nsz", .second = "fast", .folded = false },
        .{ .first = "fast", .second = "reassoc nnan nsz", .folded = false },
        .{ .first = "reassoc", .second = "reassoc", .folded = false },
        .{ .first = "nsz", .second = "nsz", .folded = false },
    };
    const shapes = [_]struct { first: []const u8, second: []const u8 }{
        .{ .first = "fadd {s} {s} %x,{s}", .second = "fsub {s} {s} %first,{s}" },
        .{ .first = "fadd {s} {s} {s},%x", .second = "fsub {s} {s} %first,{s}" },
        .{ .first = "fsub {s} {s} %x,{s}", .second = "fadd {s} {s} %first,{s}" },
        .{ .first = "fsub {s} {s} %x,{s}", .second = "fadd {s} {s} {s},%first" },
    };
    inline for (shapes) |shape| for (flags) |case| for ([_]struct { ty: []const u8, decimal: []const u8, hex: []const u8 }{
        .{ .ty = "double", .decimal = "1099511627776.0", .hex = "0x4270000000000000" },
        .{ .ty = "float", .decimal = "16777216.0", .hex = "0x4170000000000000" },
    }) |format| {
        const first = try std.fmt.allocPrint(std.testing.allocator, shape.first, .{ case.first, format.ty, format.decimal });
        defer std.testing.allocator.free(first);
        const second = try std.fmt.allocPrint(std.testing.allocator, shape.second, .{ case.second, format.ty, format.hex });
        defer std.testing.allocator.free(second);
        const text = try std.fmt.allocPrint(std.testing.allocator, "define {s} @cancel({s} %x) {{\nentry:\n %first = {s}\n %result = {s}\n ret {s} %result\n}}\n", .{ format.ty, format.ty, first, second, format.ty });
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        _ = try combine(&module);
        try module.verify();
        try std.testing.expectEqual(@as(usize, if (case.folded) 0 else 2), liveBinaries(module.functions.items[0]));
        const result = module.functions.items[0].blocks.items[0].terminator.?.ret.value.?;
        try std.testing.expect(result == .named);
        try std.testing.expectEqualStrings(if (case.folded) "x" else "result", result.named);
        try std.testing.expectEqual(pm.PassResult.unchanged, try combine(&module));
    };
}

test "floating cancellation rejects nonfinite unequal unknown and cross block operands" {
    for ([_]struct { first: []const u8, second: []const u8, gap: []const u8 = "" }{
        .{ .first = "1.0", .second = "2.0" },
        .{ .first = "0x7FF0000000000000", .second = "0x7FF0000000000000" },
        .{ .first = "0xFFF0000000000000", .second = "0xFFF0000000000000" },
        .{ .first = "0x7FF8000000000000", .second = "0x7FF8000000000000" },
        .{ .first = "%other", .second = "%other" },
        .{ .first = "1.0", .second = "1.0", .gap = "br label %next\nnext:" },
    }) |case| {
        const text = try std.fmt.allocPrint(std.testing.allocator, "define double @boundary(double %x,double %other) {{\nentry:\n %first = fadd fast double %x,{s}\n {s}\n %result = fsub fast double %first,{s}\n ret double %result\n}}\n", .{ case.first, case.gap, case.second });
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        _ = try combine(&module);
        try module.verify();
        try std.testing.expectEqual(@as(usize, 2), liveBinaries(module.functions.items[0]));
    }
}

test "floating cancellation retains a shared producer and rewrites later block uses" {
    const text =
        \\define double @shared(double %x,ptr %p) {
        \\entry:
        \\ %first = fadd fast double %x,0x4270000000000000
        \\ store double %first,ptr %p
        \\ %result = fsub fast double %first,0x4270000000000000
        \\ br label %next
        \\next:
        \\ ret double %result
        \\}
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();
    try module.verify();
    _ = try combine(&module);
    try module.verify();
    const function = module.functions.items[0];
    try std.testing.expectEqual(@as(usize, 1), liveBinaries(function));
    try std.testing.expectEqualStrings("first", function.blocks.items[0].instructions.items[1].kind.store.value.named);
    try std.testing.expectEqualStrings("x", function.blocks.items[1].terminator.?.ret.value.?.named);
    try std.testing.expectEqual(pm.PassResult.unchanged, try combine(&module));
}
