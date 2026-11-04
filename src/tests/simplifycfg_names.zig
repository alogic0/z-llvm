const std = @import("std");
const ir = @import("../ir.zig");
const pass_manager = @import("../pass_manager.zig");
const simplifycfg = @import("../passes/simplifycfg.zig");

fn check(allocator: std.mem.Allocator, input: []const u8, expected: []const u8) !void {
    var module = try ir.Module.parse(allocator, input);
    defer module.deinit();
    try module.verify();
    var context: pass_manager.Context = .{ .allocator = allocator };
    try std.testing.expectEqual(pass_manager.PassResult.changed, try simplifycfg.pass.run(&module, &context));
    try module.verify();
    var output: std.Io.Writer.Allocating = .init(allocator);
    defer output.deinit();
    module.print(&output.writer) catch |err| switch (err) {
        error.WriteFailed => return error.OutOfMemory,
        else => return err,
    };
    try std.testing.expect(std.mem.indexOf(u8, output.written(), expected) != null);
}

const collisions =
    \\define i32 @collisions(i1 %cond, i32 %"select.1") {
    \\select:
    \\  %"sel\65ct.2" = add i32 %"select.1", 1
    \\  br i1 %cond, label %yes, label %no
    \\yes:
    \\  br label %merge
    \\no:
    \\  br label %merge
    \\merge:
    \\  %"return value" = phi i32 [ %"sel\65ct.2", %yes ], [ 29, %no ]
    \\  ret i32 %"return value"
    \\}
;

test "simplifycfg generated select names handle numeric and quoted operands" {
    for ([_][]const u8{
        \\define i32 @numeric_phi(i1 %0) {
        \\entry:
        \\  br i1 %0, label %yes, label %no
        \\yes:
        \\  br label %merge
        \\no:
        \\  br label %merge
        \\merge:
        \\  %1 = phi i32 [ 17, %yes ], [ 29, %no ]
        \\  ret i32 %1
        \\}
        ,
        \\define i32 @numeric_operands(i1 %cond, i32 %0, i32 %1) {
        \\entry:
        \\  br i1 %cond, label %yes, label %no
        \\yes:
        \\  br label %merge
        \\no:
        \\  br label %merge
        \\merge:
        \\  %result = phi i32 [ %0, %yes ], [ %1, %no ]
        \\  ret i32 %result
        \\}
        ,
        \\define i32 @quoted_operands(i1 %cond, i32 %"source one", i32 %"source two") {
        \\entry:
        \\  br i1 %cond, label %yes, label %no
        \\yes:
        \\  br label %merge
        \\no:
        \\  br label %merge
        \\merge:
        \\  %result = phi i32 [ %"source one", %yes ], [ %"source two", %no ]
        \\  ret i32 %result
        \\}
        ,
    }) |input| try check(std.testing.allocator, input, "%select = select i1");
}

test "simplifycfg generated names avoid labels and quoted or escaped value names" {
    try check(std.testing.allocator, collisions, "%select.3 = select i1");
}

test "simplifycfg generated select names release partial allocations" {
    try std.testing.checkAllAllocationFailures(std.testing.allocator, check, .{ collisions, "%select.3 = select i1" });
}
