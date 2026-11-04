const std = @import("std");
const ir = @import("../ir.zig");
const block_addresses = @import("../analysis/block_addresses.zig");
const references = @import("../analysis/module_references.zig");
const pass_manager = @import("../pass_manager.zig");
const simplifycfg = @import("../passes/simplifycfg.zig");

const input =
    \\@addresses = constant [3 x ptr] [ptr blockaddress(@protected, %loop), ptr blockaddress(@protected, %dead), ptr blockaddress(@protected, %exit)]
    \\define i32 @protected(i32 %x) mustprogress {
    \\entry:
    \\  br i1 true, label %loop, label %dead
    \\loop:
    \\  %i = phi i32 [ 0, %entry ], [ %n, %loop ]
    \\  %n = add i32 %i, 1
    \\  %cond = icmp ult i32 %n, 4
    \\  br i1 %cond, label %loop, label %exit
    \\dead:
    \\  ret i32 99
    \\exit:
    \\  ret i32 %x
    \\}
    \\define i32 @plain(i32 %x) {
    \\entry:
    \\  br label %tail
    \\tail:
    \\  ret i32 %x
    \\}
    \\!blockaddress = !{!0}
    \\!0 = !{!"blockaddress(@plain, %tail)"}
;

test "block addresses guard referenced functions without interpreting quoted data as uses" {
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    var guard = try block_addresses.Guard.build(std.testing.allocator, module);
    defer guard.deinit();
    try std.testing.expect(guard.contains("protected"));
    try std.testing.expect(!guard.contains("plain"));
    try std.testing.expect(!guard.unknown);
    const query = references.query(&module, "protected");
    try std.testing.expectEqual(@as(usize, 3), query.direct_uses);
    try std.testing.expect(query.has_unknown); // No general opaque-coverage claim.
}

test "control-flow passes preserve blocks whose addresses escape through globals" {
    const passes = [_]pass_manager.ModulePass{
        simplifycfg.pass,
        @import("../passes/sccp.zig").pass,
        @import("../passes/jump_threading.zig").pass,
        @import("../passes/loop_deletion.zig").pass,
        @import("../passes/loop_simplifycfg.zig").pass,
    };
    for (passes) |pass| {
        var module = try ir.Module.parse(std.testing.allocator, input);
        defer module.deinit();
        try module.verify();
        var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
        _ = try pass.run(&module, &context);
        try module.verify();
        const function = module.functions.items[0];
        for ([_][]const u8{ "entry", "loop", "dead", "exit" }) |name| try std.testing.expect(function.blockIndex(name) != null);
        try std.testing.expectEqual(@as(usize, 4), function.blocks.items.len);
        if (std.mem.eql(u8, pass.name, "simplifycfg")) try std.testing.expectEqual(@as(usize, 1), module.functions.items[1].blocks.items.len);
    }
}

test "block addresses malformed opaque syntax prevents unsafe CFG rewrites" {
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    module.globals.items[0].initializer = .{ .@"opaque" = "[ptr blockaddress(@protected %loop)]" };
    var guard = try block_addresses.Guard.build(std.testing.allocator, module);
    defer guard.deinit();
    try std.testing.expect(guard.unknown);
    try std.testing.expect(guard.contains("plain"));
}

test "block addresses unresolved function spellings conservatively protect CFGs" {
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    module.globals.items[0].initializer = .{ .@"opaque" = "[ptr blockaddress(@\"protected\", %loop)]" };
    var guard = try block_addresses.Guard.build(std.testing.allocator, module);
    defer guard.deinit();
    try std.testing.expect(guard.unknown);
    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    try std.testing.expectEqual(pass_manager.PassResult.unchanged, try simplifycfg.pass.run(&module, &context));
    try std.testing.expectEqual(@as(usize, 4), module.functions.items[0].blocks.items.len);
    try std.testing.expectEqual(@as(usize, 2), module.functions.items[1].blocks.items.len);
}

fn allocationCheck(allocator: std.mem.Allocator, module: ir.Module) !void {
    var guard = try block_addresses.Guard.build(allocator, module);
    defer guard.deinit();
    try std.testing.expect(guard.contains("protected"));
}

test "block addresses guard releases every partial allocation" {
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try std.testing.checkAllAllocationFailures(std.testing.allocator, allocationCheck, .{module});
}
