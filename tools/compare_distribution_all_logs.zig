const std = @import("std");

const schema_version = 1;

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;
    var args = try std.process.Args.Iterator.initAllocator(init.minimal.args, allocator);
    defer args.deinit();
    _ = args.skip();
    const expected_path = args.next() orelse return error.MissingExpectedLog;
    const actual_path = args.next() orelse return error.MissingActualLog;
    if (args.next() != null) return error.UnexpectedArgument;

    const expected = try canonicalRecords(allocator, io, expected_path);
    defer freeRecords(allocator, expected);
    const actual = try canonicalRecords(allocator, io, actual_path);
    defer freeRecords(allocator, actual);

    var stderr_buffer: [4096]u8 = undefined;
    var stderr_writer = std.Io.File.stderr().writer(io, &stderr_buffer);
    if (expected.len != actual.len) {
        try stderr_writer.interface.print("canonical record count differs: expected={} actual={}\n", .{ expected.len, actual.len });
        try stderr_writer.interface.flush();
        return error.SemanticMismatch;
    }
    for (expected, actual, 0..) |expected_record, actual_record, index| {
        if (std.mem.eql(u8, expected_record, actual_record)) continue;
        try stderr_writer.interface.print(
            "canonical record changed at index {}:\nexpected: {s}\nactual:   {s}\n",
            .{ index, expected_record, actual_record },
        );
        try stderr_writer.interface.flush();
        return error.SemanticMismatch;
    }

    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    try stdout_writer.interface.print(
        "summary distribution-all-equivalence schema_version={} expected={s} actual={s} canonical_records={} semantic_match=true local_fail=0\n",
        .{ schema_version, expected_path, actual_path, expected.len },
    );
    try stdout_writer.interface.flush();
}

fn canonicalRecords(allocator: std.mem.Allocator, io: std.Io, path: []const u8) ![][]u8 {
    const contents = try std.Io.Dir.cwd().readFileAlloc(io, path, allocator, .limited(512 * 1024 * 1024));
    defer allocator.free(contents);
    var records: std.ArrayList([]u8) = .empty;
    errdefer freeRecords(allocator, records.items);
    var saw_success = false;
    var lines = std.mem.splitScalar(u8, contents, '\n');
    while (lines.next()) |line| {
        const record = canonicalRecord(allocator, line) orelse continue;
        errdefer allocator.free(record);
        if (std.mem.eql(u8, record, "ok distribution all gates")) saw_success = true;
        try records.append(allocator, record);
    }
    if (!saw_success) return error.MissingSuccessfulExitRecord;
    return try records.toOwnedSlice(allocator);
}

fn canonicalRecord(allocator: std.mem.Allocator, line: []const u8) ?[]u8 {
    if (std.mem.startsWith(u8, line, "summary distribution-all-slowest ") or
        std.mem.startsWith(u8, line, "summary distribution-all-timing ")) return null;
    if (std.mem.startsWith(u8, line, "gate-end ")) {
        const volatile_start = std.mem.indexOf(u8, line, " duration_ms=") orelse line.len;
        return allocator.dupe(u8, line[0..volatile_start]) catch null;
    }
    if (std.mem.startsWith(u8, line, "gate-start ") or
        std.mem.startsWith(u8, line, "summary ") or
        std.mem.eql(u8, line, "ok distribution all gates"))
    {
        return normalizePaths(allocator, line) catch null;
    }
    return null;
}

fn normalizePaths(allocator: std.mem.Allocator, line: []const u8) ![]u8 {
    var output: std.ArrayList(u8) = .empty;
    errdefer output.deinit(allocator);
    var rest = line;
    const repo = "/home/oleg/prog/z_llvm/";
    while (std.mem.indexOf(u8, rest, repo)) |index| {
        try output.appendSlice(allocator, rest[0..index]);
        try output.appendSlice(allocator, "<repo>/");
        rest = rest[index + repo.len ..];
    }
    try output.appendSlice(allocator, rest);
    return try output.toOwnedSlice(allocator);
}

fn freeRecords(allocator: std.mem.Allocator, records: []const []u8) void {
    for (records) |record| allocator.free(record);
    allocator.free(records);
}

test "canonical records ignore only distribution timing observations" {
    const allocator = std.testing.allocator;
    const end = canonicalRecord(allocator, "gate-end tool=x duration_ms=12 cache_status=hit").?;
    defer allocator.free(end);
    try std.testing.expectEqualStrings("gate-end tool=x", end);
    try std.testing.expect(canonicalRecord(allocator, "summary distribution-all-timing subgates=17 total_duration_ms=1") == null);
    const semantic = canonicalRecord(allocator, "summary gate total=4 local_fail=0").?;
    defer allocator.free(semantic);
    try std.testing.expectEqualStrings("summary gate total=4 local_fail=0", semantic);
}
