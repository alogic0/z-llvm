const std = @import("std");
const sharding = @import("run_distribution_zig_integrated_object_sharding.zig");

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;
    var args = try std.process.Args.Iterator.initAllocator(init.minimal.args, allocator);
    defer args.deinit();
    _ = args.next();
    const path = args.next() orelse return error.MissingInputPath;
    if (args.next() != null) return error.UnexpectedArgument;
    const contents = try std.Io.Dir.cwd().readFileAlloc(io, path, allocator, .limited(128 * 1024 * 1024));
    defer allocator.free(contents);
    var buffer: [4096]u8 = undefined;
    var stdout = std.Io.File.stdout().writer(io, &buffer);
    try sharding.writeNormalizedOutput(contents, &stdout.interface);
    try stdout.interface.flush();
}
