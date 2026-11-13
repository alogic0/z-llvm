const std = @import("std");
const ir = @import("../../../ir.zig");
const machine = @import("../machine.zig");
const selector = @import("../generic_cfg_selector.zig");
const encoding = @import("../../../mc/encoding.zig");

fn executable(module: ir.Module) ![]align(std.heap.page_size_min) u8 {
    const function = module.functions.items[0];
    var output = machine.MachineFunction.init(function.name, function.ret_ty);
    defer output.deinit(std.testing.allocator);
    const selected = try selector.tryLower(std.testing.allocator, &output, function);
    if (selected == .unsupported) std.debug.print("variadic {s}: {s}\n", .{ function.name, selected.unsupported.detail() });
    try std.testing.expectEqual(selector.SelectionResult.selected, selected);
    try @import("../verify.zig").verifyFunction(output);
    const code = try encoding.encodeFunction(std.testing.allocator, output);
    defer std.testing.allocator.free(code);
    const memory = try std.posix.mmap(null, code.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    @memcpy(memory[0..code.len], code);
    return memory;
}

test "variadic integer cursor crosses all GP registers into incoming stack" {
    var module = try ir.Module.parse(std.testing.allocator,
        \\declare void @llvm.va_start.p0(ptr)
        \\declare void @llvm.va_end.p0(ptr)
        \\define i64 @sum(i32 %count, ...) {
        \\entry:
        \\ %list = alloca [24 x i8], align 8
        \\ call void @llvm.va_start.p0(ptr %list)
        \\ br label %loop
        \\loop:
        \\ %i = phi i32 [ 0, %entry ], [ %next, %loop ]
        \\ %sum = phi i64 [ 0, %entry ], [ %added, %loop ]
        \\ %value = va_arg ptr %list, i64
        \\ %added = add i64 %sum, %value
        \\ %next = add i32 %i, 1
        \\ %again = icmp ult i32 %next, %count
        \\ br i1 %again, label %loop, label %exit
        \\exit:
        \\ call void @llvm.va_end.p0(ptr %list)
        \\ ret i64 %added
        \\}
    );
    defer module.deinit();
    try module.verify();
    const memory = try executable(module);
    defer std.posix.munmap(memory);
    const run: *const fn (u32, ...) callconv(.c) u64 = @ptrCast(memory.ptr);
    try std.testing.expectEqual(@as(u64, 11), run(1, @as(u64, 11)));
    try std.testing.expectEqual(@as(u64, 55), run(10, @as(u64, 1), @as(u64, 2), @as(u64, 3), @as(u64, 4), @as(u64, 5), @as(u64, 6), @as(u64, 7), @as(u64, 8), @as(u64, 9), @as(u64, 10)));
    try module.verify();
}

test "variadic floating cursor crosses eight SSE registers into incoming stack" {
    var module = try ir.Module.parse(std.testing.allocator,
        \\declare void @llvm.va_start.p0(ptr)
        \\define double @sum(i32 %count, ...) {
        \\entry:
        \\ %list = alloca [24 x i8], align 8
        \\ call void @llvm.va_start.p0(ptr %list)
        \\ br label %loop
        \\loop:
        \\ %i = phi i32 [ 0, %entry ], [ %next, %loop ]
        \\ %sum = phi double [ 0.000000e+00, %entry ], [ %added, %loop ]
        \\ %value = va_arg ptr %list, double
        \\ %added = fadd double %sum, %value
        \\ %next = add i32 %i, 1
        \\ %again = icmp ult i32 %next, %count
        \\ br i1 %again, label %loop, label %exit
        \\exit:
        \\ ret double %added
        \\}
    );
    defer module.deinit();
    try module.verify();
    const memory = try executable(module);
    defer std.posix.munmap(memory);
    const run: *const fn (u32, ...) callconv(.c) f64 = @ptrCast(memory.ptr);
    try std.testing.expectEqual(@as(f64, 1.5), run(1, @as(f64, 1.5)));
    try std.testing.expectEqual(@as(f64, 55), run(10, @as(f64, 1), @as(f64, 2), @as(f64, 3), @as(f64, 4), @as(f64, 5), @as(f64, 6), @as(f64, 7), @as(f64, 8), @as(f64, 9), @as(f64, 10)));
    try module.verify();
}

test "annotated variadic pointers preserve independent copied cursors and overflow arguments" {
    var module = try ir.Module.parse(std.testing.allocator,
        \\declare void @llvm.va_start.p0(ptr)
        \\declare void @llvm.va_copy.p0(ptr,ptr)
        \\declare void @llvm.va_end.p0(ptr)
        \\attributes #7 = { nounwind }
        \\define i64 @sum(i32 %count, ...) {
        \\entry:
        \\ %list = alloca [24 x i8],align 16
        \\ %copy = alloca [24 x i8],align 16
        \\ call void @llvm.va_start.p0(ptr noundef nonnull align 16 dereferenceable(24) %list) #7
        \\ call void @llvm.va_copy.p0(ptr nonnull %copy,ptr noundef nonnull align 16 dereferenceable(24) %list) #7
        \\ %first = va_arg ptr %list,i64
        \\ br label %loop
        \\loop:
        \\ %i = phi i32 [0,%entry],[%next,%loop]
        \\ %sum = phi i64 [0,%entry],[%added,%loop]
        \\ %value = va_arg ptr %copy,i64
        \\ %added = add i64 %sum,%value
        \\ %next = add i32 %i,1
        \\ %again = icmp ult i32 %next,%count
        \\ br i1 %again,label %loop,label %exit
        \\exit:
        \\ call void @llvm.va_end.p0(ptr nonnull %copy) #7
        \\ call void @llvm.va_end.p0(ptr nonnull %list) #7
        \\ %answer = add i64 %added,%first
        \\ ret i64 %answer
        \\}
    );
    defer module.deinit();
    try module.verify();
    const memory = try executable(module);
    defer std.posix.munmap(memory);
    const run: *const fn (u32, ...) callconv(.c) u64 = @ptrCast(memory.ptr);
    try std.testing.expectEqual(@as(u64, 22), run(1, @as(u64, 11)));
    try std.testing.expectEqual(@as(u64, 56), run(10, @as(u64, 1), @as(u64, 2), @as(u64, 3), @as(u64, 4), @as(u64, 5), @as(u64, 6), @as(u64, 7), @as(u64, 8), @as(u64, 9), @as(u64, 10)));
    try std.testing.expectEqualStrings("noundef nonnull align 16 dereferenceable(24)", module.functions.items[0].blocks.items[0].instructions.items[2].kind.call.args.items[0].attrs.?);
    try module.verify();
}
