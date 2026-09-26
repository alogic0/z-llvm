const std = @import("std");
const ir = @import("../ir.zig");

const input =
    \\@g = global i32 0
    \\@a = alias i32, ptr @g
    \\declare void @sink(i32)
    \\define i32 @first(i1 %c, i32 %x) {
    \\entry:
    \\  br i1 %c, label %left, label %right
    \\left:
    \\  %a = add i32 %x, 1
    \\  br label %join
    \\right:
    \\  %b = sub i32 %x, 1
    \\  br label %join
    \\join:
    \\  %v = phi i32 [ %a, %left ], [ %b, %right ]
    \\  call void @sink(i32 %v)
    \\  ret i32 %v
    \\}
    \\define i32 @second(i32 %x) {
    \\entry:
    \\  %v = add i32 %x, 1
    \\  ret i32 %v
    \\}
;

fn verifyWithAllocator(allocator: std.mem.Allocator, original: ir.Module, invalid: bool) !void {
    // The verifier only borrows IR. Inject failures into its own allocations,
    // leaving the parsed module's storage owned by the outer testing allocator.
    var borrowed = original;
    borrowed.allocator = allocator;
    borrowed.verify() catch |err| {
        if (err == error.OutOfMemory) return err;
        if (invalid and err == error.UnknownValue) return;
        return err;
    };
    try std.testing.expect(!invalid);
}

test "verifier allocation: every allocation failure cleans up across multiple functions" {
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try std.testing.checkAllAllocationFailures(std.testing.allocator, verifyWithAllocator, .{ module, false });
    try module.verify();
}

test "verifier allocation: invalid IR and allocation failures both clean up" {
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    module.functions.items[1].blocks.items[0].terminator.?.ret.value = .{ .named = "missing" };
    try std.testing.checkAllAllocationFailures(std.testing.allocator, verifyWithAllocator, .{ module, true });
    try std.testing.expectError(error.UnknownValue, module.verify());
}
