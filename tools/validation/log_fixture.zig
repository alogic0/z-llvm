//! Independent positional writers reproduce redirected diagnostic loss.
const std = @import("std");

pub fn main(init: std.process.Init) !void {
    var buffer: [128]u8 = undefined;
    var first = std.Io.File.stdout().writer(init.io, &buffer);
    try first.interface.writeAll("before\x00out\n");
    try first.interface.flush();
    var diagnostic = std.Io.File.stderr().writer(init.io, &buffer);
    try diagnostic.interface.writeAll("diagnostic\n");
    try diagnostic.interface.flush();
    var last = std.Io.File.stdout().writer(init.io, &buffer);
    try last.interface.writeAll("after\n");
    try last.interface.flush();
    return error.IntentionalLogFailure;
}
