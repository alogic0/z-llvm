const std = @import("std");
const ir = @import("../../../ir.zig");
const encoding = @import("../../../mc/encoding.zig");
const machine = @import("../machine.zig");
const verify = @import("../verify.zig");
const selector = @import("../generic_cfg_selector.zig");

test "aggregate GEPs retain scalar allocation padding through nested arrays" {
    const bytes = try std.Io.Dir.cwd().readFileAlloc(std.testing.io, "test/real_programs/type_layout_padding.ll", std.testing.allocator, .limited(1024 * 1024));
    defer std.testing.allocator.free(bytes);
    var module = try ir.Module.parse(std.testing.allocator, bytes);
    defer module.deinit();
    try module.verify();
    const ctx: machine.ReadOnlyModuleContext = .{ .globals = module.globals.items, .named_types = module.named_types.items, .target_datalayout = module.target_datalayout };
    const expected = [_]usize{ 4, 16, 8, 16 };
    try std.testing.expectEqual(expected.len, module.functions.items.len);
    for (module.functions.items, expected) |function, offset| {
        var lowered = machine.MachineFunction.init(function.name, function.ret_ty);
        defer lowered.deinit(std.testing.allocator);
        switch (try selector.tryLowerWithContext(std.testing.allocator, &lowered, function, &ctx)) {
            .selected => {},
            .unsupported => |diagnostic| {
                std.debug.print("layout selection {s}: {s}\n", .{ function.name, diagnostic.detail() });
                return error.TestUnexpectedResult;
            },
        }
        try verify.verifyFunction(lowered);
        try std.testing.expect(lowered.selection_owner == .composed_block or lowered.selection_owner == .composed_cfg);
        const code = try encoding.encodeFunction(std.testing.allocator, lowered);
        defer std.testing.allocator.free(code);
        const executable = try std.posix.mmap(null, code.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        defer std.posix.munmap(executable);
        @memcpy(executable[0..code.len], code);
        const run: *const fn (*anyopaque) callconv(.c) *anyopaque = @ptrCast(executable.ptr);
        var buffer: [96]u8 = undefined;
        for (0..32) |base| try std.testing.expectEqual(@intFromPtr(&buffer[base]) + offset, @intFromPtr(run(&buffer[base])));
    }
}
