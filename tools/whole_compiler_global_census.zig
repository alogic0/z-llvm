//! Independent global syntax diagnostics; no verification or emission credit.
//! Run with --dep ir -Mroot=tools/whole_compiler_global_census.zig -Mir=src/ir.zig.
const std = @import("std");
const ir = @import("ir");
pub fn main(init: std.process.Init) !void {
    const args = try init.minimal.args.toSlice(init.arena.allocator());
    if (args.len != 3) return error.ExpectedInputAndFirstFailureOutput;
    const input = try std.Io.Dir.cwd().readFileAlloc(init.io, args[1], init.gpa, .limited(2 * 1024 * 1024 * 1024));
    defer init.gpa.free(input);
    const first_failure = try std.Io.Dir.cwd().createFile(init.io, args[2], .{ .exclusive = true });
    defer first_failure.close(init.io);
    var buffer: [65536]u8 = undefined;
    var output = std.Io.File.stdout().writerStreaming(init.io, &buffer);
    const w = &output.interface;
    var lines = std.mem.splitScalar(u8, input, '\n');
    var number: usize = 0;
    var examined: usize = 0;
    var rejected: usize = 0;
    while (lines.next()) |line| {
        number += 1;
        if (!std.mem.startsWith(u8, line, "@")) continue;
        examined += 1;
        if (ir.Module.parse(init.gpa, line)) |parsed| {
            var module = parsed;
            module.deinit();
        } else |err| {
            if (err == error.OutOfMemory) return err;
            if (rejected == 0) try first_failure.writeStreamingAll(init.io, line);
            rejected += 1;
            const name_end = std.mem.indexOf(u8, line, " = ") orelse line.len;
            const kind_at = std.mem.indexOf(u8, line, " global ") orelse 0;
            const tls_at = std.mem.indexOf(u8, line, "thread_local");
            try std.json.Stringify.value(.{ .line = number, .name = line[0..name_end], .error_name = @errorName(err), .thread_local = if (tls_at) |at| at < kind_at else false, .prefix = line[0..@min(line.len, 512)] }, .{}, w);
            try w.writeByte('\n');
        }
    }
    try std.json.Stringify.value(.{ .scope = "independent global/alias syntax parsing only; no verification, reachability or function acceptance", .examined = examined, .rejected = rejected }, .{}, w);
    try w.writeByte('\n');
    try w.flush();
}
