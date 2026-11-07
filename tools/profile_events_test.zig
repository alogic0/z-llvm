const std = @import("std");
const process = @import("vendor/process/src/root.zig");
const options = @import("test_options");
const a = std.testing.allocator;
const io = std.testing.io;

const Counts = struct {
    begins: usize = 0,
    ends: usize = 0,
    pending_legalizer: bool = false,
    complete: bool = false,
};

fn inspect(bytes: []const u8) !Counts {
    try std.testing.expect(std.mem.endsWith(u8, bytes, "\n"));
    var result: Counts = .{};
    var lines = std.mem.tokenizeScalar(u8, bytes, '\n');
    var sequence: i64 = 0;
    var timestamp: i64 = 0;
    while (lines.next()) |line| {
        try std.testing.expect(!result.complete);
        const parsed = try std.json.parseFromSlice(std.json.Value, a, line, .{});
        defer parsed.deinit();
        const object = parsed.value.object;
        try std.testing.expectEqualStrings("compilation-events-v1", object.get("schema").?.string);
        try std.testing.expectEqual(sequence, object.get("sequence").?.integer);
        const elapsed = object.get("elapsed_ns").?.integer;
        try std.testing.expect(elapsed >= timestamp);
        timestamp = elapsed;
        sequence += 1;
        const event = object.get("event").?.string;
        if (std.mem.eql(u8, event, "function_begin")) {
            try std.testing.expectEqual(result.begins, result.ends);
            result.begins += 1;
        } else if (std.mem.eql(u8, event, "function_end")) {
            try std.testing.expect(!result.pending_legalizer);
            try std.testing.expectEqual(result.begins, result.ends + 1);
            result.ends += 1;
        } else if (std.mem.eql(u8, event, "legalizer_begin")) {
            try std.testing.expect(!result.pending_legalizer);
            result.pending_legalizer = true;
        } else if (std.mem.eql(u8, event, "legalizer_end")) {
            try std.testing.expect(result.pending_legalizer);
            result.pending_legalizer = false;
        } else if (std.mem.eql(u8, event, "profile_end")) {
            try std.testing.expectEqual(result.begins, result.ends);
            try std.testing.expect(!result.pending_legalizer);
            try std.testing.expect(object.get("details").?.object.get("succeeded").?.bool);
            result.complete = true;
        }
    }
    return result;
}

test "profiling preserves object bytes and rejects conflicting paths before writing" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    var buffer: [4096]u8 = undefined;
    const directory = buffer[0..try tmp.dir.realPath(io, &buffer)];
    const input = try std.fs.path.join(a, &.{ directory, "input.ll" });
    defer a.free(input);
    const events = try std.fs.path.join(a, &.{ directory, "events.jsonl" });
    defer a.free(events);
    const profile = try std.fs.path.join(a, &.{ directory, "profile.json" });
    defer a.free(profile);
    const owner = try std.fs.path.join(a, &.{ directory, "owners.tsv" });
    defer a.free(owner);
    const program =
        \\target triple = "x86_64-unknown-linux-gnu"
        \\declare void @clobber()
        \\define i64 @ordinary(i64 %x) {
        \\entry:
        \\ %y = add i64 %x, 3
        \\ ret i64 %y
        \\}
        \\define i64 @memory(ptr %p, i64 %x) {
        \\entry:
        \\ store i64 %x, ptr %p, align 1
        \\ call void @clobber()
        \\ %result = load i64, ptr %p, align 1
        \\ ret i64 %result
        \\}
    ;
    try tmp.dir.writeFile(io, .{ .sub_path = "input.ll", .data = program });
    const ordinary = try process.runReport(a, io, .{ .spawn = .{ .argv = &.{ options.compiler, "--emit=obj", "--generic-cfg-selector", input } } });
    defer ordinary.deinit(a);
    if (!ordinary.success()) std.debug.print("ordinary compiler: {s}\n", .{ordinary.stderr});
    try std.testing.expect(ordinary.success());
    const profile_arg = try std.fmt.allocPrint(a, "--profile={s}", .{profile});
    defer a.free(profile_arg);
    const events_arg = try std.fmt.allocPrint(a, "--profile-events={s}", .{events});
    defer a.free(events_arg);
    const measured = try process.runReport(a, io, .{ .spawn = .{ .argv = &.{ options.compiler, "--emit=obj", "--generic-cfg-selector", profile_arg, events_arg, input } } });
    defer measured.deinit(a);
    if (!measured.success()) std.debug.print("profiled compiler: {s}\n", .{measured.stderr});
    try std.testing.expect(measured.success());
    try std.testing.expectEqualSlices(u8, ordinary.stdout, measured.stdout);
    const bytes = try tmp.dir.readFileAlloc(io, "events.jsonl", a, .limited(1024 * 1024));
    defer a.free(bytes);
    const counts = try inspect(bytes);
    try std.testing.expect(counts.complete);
    try std.testing.expectEqual(2, counts.ends);
    try tmp.dir.writeFile(io, .{ .sub_path = "owners.tsv", .data = "retained owner" });
    const owner_arg = try std.fmt.allocPrint(a, "--selection-owner-output={s}", .{owner});
    defer a.free(owner_arg);
    try tmp.dir.symLink(io, "input.ll", "input-alias.ll", .{});
    const alias = try std.fs.path.join(a, &.{ directory, "input-alias.ll" });
    defer a.free(alias);
    const dotted = try std.fmt.allocPrint(a, "{s}/./input.ll", .{directory});
    defer a.free(dotted);
    for ([_][]const u8{ input, profile, owner, alias, dotted }) |conflict| {
        const conflict_arg = try std.fmt.allocPrint(a, "--profile-events={s}", .{conflict});
        defer a.free(conflict_arg);
        const rejected = try process.runReport(a, io, .{ .spawn = .{ .argv = &.{ options.compiler, "--emit=obj", profile_arg, owner_arg, conflict_arg, input } } });
        defer rejected.deinit(a);
        try std.testing.expect(rejected.outcome == .completed and !rejected.success());
        try std.testing.expect(std.mem.indexOf(u8, rejected.stderr, "ConflictingOutputPaths") != null);
    }
    const retained = try tmp.dir.readFileAlloc(io, "input.ll", a, .limited(65536));
    defer a.free(retained);
    try std.testing.expectEqualStrings(program, retained);
    const retained_owner = try tmp.dir.readFileAlloc(io, "owners.tsv", a, .limited(65536));
    defer a.free(retained_owner);
    try std.testing.expectEqualStrings("retained owner", retained_owner);
}

test "owned process timeout retains the active function and legalizer without completion credit" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    var buffer: [4096]u8 = undefined;
    const directory = buffer[0..try tmp.dir.realPath(io, &buffer)];
    const events = try std.fs.path.join(a, &.{ directory, "events.jsonl" });
    defer a.free(events);
    const interrupted = try process.runReport(a, io, .{ .spawn = .{ .argv = &.{ options.probe, events } }, .timeout_ms = 1000 });
    defer interrupted.deinit(a);
    try std.testing.expect(interrupted.outcome == .timed_out);
    try std.testing.expect(interrupted.cleanup_failure == null);
    const bytes = try tmp.dir.readFileAlloc(io, "events.jsonl", a, .limited(65536));
    defer a.free(bytes);
    const counts = try inspect(bytes);
    try std.testing.expectEqual(1, counts.begins);
    try std.testing.expectEqual(0, counts.ends);
    try std.testing.expect(counts.pending_legalizer and !counts.complete);
    try std.testing.expect(std.mem.indexOf(u8, bytes, "unfinished-stage") != null);
}
