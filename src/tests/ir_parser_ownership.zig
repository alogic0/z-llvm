const std = @import("std");
const ir = @import("../ir.zig");

fn parseAndRelease(allocator: std.mem.Allocator, input: []const u8) !void {
    // The cmpxchg type builder uses an allocating writer, whose allocation
    // failure is reported as WriteFailed rather than OutOfMemory.
    var module = ir.Module.parse(allocator, input) catch |err| switch (err) {
        error.WriteFailed => return error.OutOfMemory,
        else => return err,
    };
    defer module.deinit();
}

test "parser ownership survives failed function and declaration publication" {
    for ([_][]const u8{
        \\define i32 @identity(i32 %x) {
        \\entry:
        \\  ret i32 %x
        \\}
        ,
        \\declare i32 @callee(i32, i64, ptr)
        ,
    }) |input| try std.testing.checkAllAllocationFailures(std.testing.allocator, parseAndRelease, .{input});
}

test "parser ownership survives failed array global publication" {
    for ([_][]const u8{
        \\@values = global [2 x i64] [i64 1, i64 2]
        ,
        \\@marker = global i64 0
        \\@values = global [2 x i64] [i64 1, i64 2]
        ,
    }) |input| try std.testing.checkAllAllocationFailures(std.testing.allocator, parseAndRelease, .{input});
}

test "parser ownership survives failed instruction publication with owned operands" {
    for ([_][]const u8{
        \\declare i32 @callee(i32)
        \\define i32 @caller(i32 %x) {
        \\entry:
        \\  %r = call i32 @callee(i32 %x)
        \\  ret i32 %r
        \\}
        ,
        \\define i32 @phi(i32 %x) {
        \\entry:
        \\  br label %merge
        \\merge:
        \\  %r = phi i32 [ %x, %entry ]
        \\  ret i32 %r
        \\}
        ,
        \\define ptr @index(ptr %p, i64 %i) {
        \\entry:
        \\  %r = getelementptr i64, ptr %p, i64 %i
        \\  ret ptr %r
        \\}
        ,
        \\define void @exchange(ptr %p) {
        \\entry:
        \\  %r = cmpxchg ptr %p, i64 0, i64 1 monotonic monotonic
        \\  ret void
        \\}
        ,
    }) |input| try std.testing.checkAllAllocationFailures(std.testing.allocator, parseAndRelease, .{input});
}

test "parser ownership survives instruction list growth and terminator allocation" {
    try std.testing.checkAllAllocationFailures(std.testing.allocator, parseAndRelease, .{
        \\declare i32 @callee(i32)
        \\define i32 @growth(i32 %x) {
        \\entry:
        \\  %a = add i32 %x, 1
        \\  %b = add i32 %a, 1
        \\  %c = add i32 %b, 1
        \\  %d = add i32 %c, 1
        \\  %e = add i32 %d, 1
        \\  %f = add i32 %e, 1
        \\  %g = add i32 %f, 1
        \\  %h = add i32 %g, 1
        \\  %r = call i32 @callee(i32 %h)
        \\  switch i32 %r, label %other [
        \\    i32 0, label %zero
        \\  ]
        \\zero:
        \\  ret i32 0
        \\other:
        \\  ret i32 %r
        \\}
    });
}
