const std = @import("std");
const ir = @import("../../../ir.zig");
test "boolean results with floating arguments use masked ordinary ABI carriers" {
    const a = std.testing.allocator;
    for ([_][]const u8{ "half", "float", "double", "x86_fp80", "fp128" }) |ty| {
        const source = try std.fmt.allocPrint(a, "declare i1 @predicate({0s},{0s})\ndefine i32 @probe({0s} %a,{0s} %b) {{\nentry:\n %r = tail call i1 @predicate({0s} %a,{0s} %b)\n %z = zext i1 %r to i32\n ret i32 %z\n}}\n", .{ty});
        defer a.free(source);
        var module = try ir.Module.parse(a, source);
        defer module.deinit();
        try module.verify();
        var arena = std.heap.ArenaAllocator.init(a);
        defer arena.deinit();
        const original = module.functions.items[0];
        const view = (try @import("narrow_abi.zig").legalize(arena.allocator(), original)).?;
        try std.testing.expect(view.blocks.items[0].instructions.items[0].kind.call.ret_ty.eql(.{ .int = 32 }));
        try std.testing.expect(original.blocks.items[0].instructions.items[0].kind.call.ret_ty.eql(.{ .int = 1 }));
        try std.testing.expectEqualStrings("tail", original.blocks.items[0].instructions.items[0].kind.call.tail_kind.?);
        var masks: usize = 0;
        for (view.blocks.items[0].instructions.items) |inst| if (inst.kind == .binary and inst.kind.binary.op == .@"and" and inst.kind.binary.rhs == .int and inst.kind.binary.rhs.int == 1) {
            masks += 1;
        };
        try std.testing.expectEqual(@as(usize, 1), masks);
        try module.verify();
    }
}
