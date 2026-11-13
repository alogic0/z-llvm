const std = @import("std");
const ir = @import("../../../ir.zig");
test "unused numeric variadic parameters retain argument positions in framed control flow" {
    const a = std.testing.allocator;
    var module = try ir.Module.parse(a,
        \\%VaList = type { i32,i32,ptr,ptr }
        \\declare void @llvm.va_start.p0(ptr)
        \\declare void @llvm.va_end.p0(ptr)
        \\declare void @llvm.memcpy.p0.p0.i64(ptr,ptr,i64,i1)
        \\define i32 @third(i32 %0,...) {
        \\entry:
        \\ %list = alloca %VaList,align 8
        \\ %copy = alloca %VaList,align 8
        \\ call void @llvm.va_start.p0(ptr nonnull %list)
        \\ call void @llvm.memcpy.p0.p0.i64(ptr %copy,ptr %list,i64 24,i1 false)
        \\ %first = va_arg ptr %copy,i32
        \\ %second = va_arg ptr %copy,i32
        \\ call void @llvm.va_end.p0(ptr nonnull %copy)
        \\ ret i32 %second
        \\}
    );
    defer module.deinit();
    try module.verify();
    const machine = @import("../machine.zig");
    const context: machine.ReadOnlyModuleContext = .{ .globals = module.globals.items, .named_types = module.named_types.items, .target_datalayout = null, .functions = module.functions.items, .declarations = module.declarations.items };
    var selected = try @import("../../../compilation.zig").select(a, "x86_64-unknown-linux-gnu", module.functions.items[0], .{ .generic_cfg_selector = true, .module_context = &context });
    defer selected.deinit(a);
    try @import("../verify.zig").verifyFunction(selected);
    const bytes = try @import("../../../mc/encoding.zig").encodeFunction(a, selected);
    defer a.free(bytes);
    const memory = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(memory);
    @memcpy(memory[0..bytes.len], bytes);
    const run: *const fn (u32, ...) callconv(.c) u32 = @ptrCast(memory.ptr);
    try std.testing.expectEqual(@as(u32, 22), run(0x77777777, @as(u32, 11), @as(u32, 22)));
    try module.verify();
}
