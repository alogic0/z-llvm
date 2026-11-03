//! Process fixture for the production tool_common regex assertions.
const std = @import("std");
const common = @import("tool_common.zig");

pub fn main(init: std.process.Init) !void {
    const args = try init.minimal.args.toSlice(init.arena.allocator());
    if (args.len != 4) return error.ExpectedModePathPattern;
    if (std.mem.eql(u8, args[1], "match")) {
        try common.expectRegex(init.gpa, init.io, args[2], args[3]);
    } else if (std.mem.eql(u8, args[1], "absent")) {
        try common.expectNoRegex(init.gpa, init.io, args[2], args[3]);
    } else return error.UnknownMode;
}
