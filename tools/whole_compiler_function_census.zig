//! Independent definition syntax census, without verification or codegen credit.
//! Run with --dep ir -Mroot=tools/whole_compiler_function_census.zig -Mir=src/ir.zig.
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
    var start: ?usize = null;
    var start_line: usize = 0;
    var header: []const u8 = "";
    var examined: usize = 0;
    var rejected: usize = 0;
    while (lines.next()) |line| {
        number += 1;
        if (std.mem.startsWith(u8, line, "define ")) {
            if (start != null) return error.NestedDefinition;
            start = @intFromPtr(line.ptr) - @intFromPtr(input.ptr);
            start_line = number;
            header = line;
        } else if (std.mem.eql(u8, std.mem.trim(u8, line, " \t\r"), "}")) {
            const begin = start orelse return error.UnexpectedDefinitionEnd;
            const end = @intFromPtr(line.ptr) - @intFromPtr(input.ptr) + line.len;
            const definition = input[begin..end];
            examined += 1;
            if (ir.Module.parse(init.gpa, definition)) |parsed| {
                var module = parsed;
                defer module.deinit();
                if (module.functions.items.len != 1) return error.InvalidDefinitionInventory;
            } else |err| {
                if (err == error.OutOfMemory) return err;
                if (rejected == 0) try first_failure.writeStreamingAll(init.io, definition);
                rejected += 1;
                try std.json.Stringify.value(.{ .line = start_line, .header = header, .error_name = @errorName(err) }, .{}, w);
                try w.writeByte('\n');
            }
            start = null;
        }
    }
    if (start != null) return error.UnterminatedDefinition;
    try std.json.Stringify.value(.{ .scope = "independent definition syntax parsing only; no verification, reachability or function acceptance", .examined = examined, .rejected = rejected }, .{}, w);
    try w.writeByte('\n');
    try w.flush();
}
