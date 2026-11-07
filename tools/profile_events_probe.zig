//! Child fixture: deliberately interrupted inside an unfinished legalizer.
const std = @import("std");
const profiling = @import("profile");

pub fn main(init: std.process.Init) !void {
    const args = try init.minimal.args.toSlice(init.arena.allocator());
    if (args.len != 2) return error.ExpectedEventPath;
    var p = profiling.Profile.init(init.gpa, init.io);
    defer p.deinit();
    try p.startEvents(args[1]);
    defer p.finishEvents(true) catch @panic("event write failed");
    const function = try p.beginFunction("unfinished\"function\n", 3, 10);
    defer function.end();
    const phase = profiling.enter(&p, .legalize);
    defer phase.end();
    var attempt = profiling.Attempt.init(&p, 0, "unfinished-stage", init.gpa);
    defer attempt.end();
    try std.Io.sleep(init.io, .fromSeconds(30), .awake);
}
