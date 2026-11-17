const std = @import("std");
const u = @import("validation/common.zig");
test {
    std.testing.refAllDecls(@import("storage_cleanup/interrupted_workspaces.zig"));
    std.testing.refAllDecls(@import("storage_cleanup/workspaces.zig"));
}
test "interrupted recovery never completes an unfinished monitor" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const value = try u.toValue(arena.allocator(), .{ .status = "running", .child_admitted = true, .owner_resolution = "passed" });
    try std.testing.expect(!@import("storage_cleanup/workspaces.zig").closed(value));
}
