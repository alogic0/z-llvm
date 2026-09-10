const std = @import("std");

const schema_version = 3;

const CanonicalLog = struct {
    records: [][]u8,
    gate_count: usize,
};

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;
    var args = try std.process.Args.Iterator.initAllocator(init.minimal.args, allocator);
    defer args.deinit();
    _ = args.skip();
    const expected_path = args.next() orelse return error.MissingExpectedLog;
    const actual_path = args.next() orelse return error.MissingActualLog;
    if (args.next() != null) return error.UnexpectedArgument;

    var repo_path_buffer: [std.Io.Dir.max_path_bytes]u8 = undefined;
    const repo_path_len = try std.Io.Dir.cwd().realPathFile(io, ".", &repo_path_buffer);
    const repo_path = repo_path_buffer[0..repo_path_len];

    const expected = try canonicalLog(allocator, io, expected_path, repo_path);
    defer freeLog(allocator, expected);
    const actual = try canonicalLog(allocator, io, actual_path, repo_path);
    defer freeLog(allocator, actual);

    var stderr_buffer: [4096]u8 = undefined;
    var stderr_writer = std.Io.File.stderr().writer(io, &stderr_buffer);
    if (expected.records.len != actual.records.len) {
        try stderr_writer.interface.print(
            "canonical record count differs: expected={} actual={}\n",
            .{ expected.records.len, actual.records.len },
        );
        try stderr_writer.interface.flush();
        return error.SemanticMismatch;
    }
    for (expected.records, actual.records, 0..) |expected_record, actual_record, index| {
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
        "summary distribution-all-equivalence schema_version={} expected={s} actual={s} gates={} canonical_records={} semantic_match=true local_fail=0\n",
        .{ schema_version, expected_path, actual_path, expected.gate_count, expected.records.len },
    );
    try stdout_writer.interface.flush();
}

fn canonicalLog(
    allocator: std.mem.Allocator,
    io: std.Io,
    path: []const u8,
    repo_path: []const u8,
) !CanonicalLog {
    const contents = try std.Io.Dir.cwd().readFileAlloc(io, path, allocator, .limited(512 * 1024 * 1024));
    defer allocator.free(contents);
    // Serial roots are explicitly selected and need not contain a numeric PID.
    // Normalize only the root declared by this log's preflight record.
    var serial_root: ?[]const u8 = null;
    var preflight_lines = std.mem.splitScalar(u8, contents, '\n');
    while (preflight_lines.next()) |line| {
        if (!std.mem.startsWith(u8, line, "summary distribution-all-serial-run ")) continue;
        if (serial_root != null) return error.DuplicateSerialPreflight;
        serial_root = fieldValue(line, "scratch_path") orelse return error.MissingSerialRoot;
        if (serial_root.?.len == 0) return error.MissingSerialRoot;
    }
    const normalized = if (serial_root) |root| try std.mem.replaceOwned(u8, allocator, contents, root, "tmp/serial_<run>") else try allocator.dupe(u8, contents);
    defer allocator.free(normalized);
    var records: std.ArrayList([]u8) = .empty;
    errdefer {
        for (records.items) |record| allocator.free(record);
        records.deinit(allocator);
    }
    var lines = std.mem.splitScalar(u8, normalized, '\n');
    while (lines.next()) |line| {
        const record = try canonicalRecord(allocator, line, repo_path) orelse continue;
        errdefer allocator.free(record);
        try records.append(allocator, record);
    }
    const owned_records = try records.toOwnedSlice(allocator);
    errdefer freeRecords(allocator, owned_records);
    return .{
        .records = owned_records,
        .gate_count = try validateStructure(allocator, owned_records),
    };
}

fn canonicalRecord(
    allocator: std.mem.Allocator,
    line: []const u8,
    repo_path: []const u8,
) !?[]u8 {
    if (line.len == 0 or
        std.mem.startsWith(u8, line, "headroom-") or
        std.mem.startsWith(u8, line, "summary distribution-all-slowest ") or
        std.mem.startsWith(u8, line, "summary distribution-all-timing ")) return null;

    if (std.mem.startsWith(u8, line, "real-rows-mode-parallel ")) {
        // Use the runner's versioned telemetry contract rather than dropping an
        // arbitrary record merely because it contains volatile fields.
        var discarded: std.Io.Writer.Discarding = .init(&.{});
        try @import("run_distribution_real_rows_parallel.zig").writeNormalizedOutput(line, &discarded.writer);
        return null;
    }

    const semantic = if (std.mem.startsWith(u8, line, "gate-end "))
        try removeFields(allocator, line, &.{ "duration_ms", "cache_status" })
    else if (std.mem.startsWith(u8, line, "gate-input "))
        try removeFields(allocator, line, &.{"cache_mode"})
    else if (std.mem.startsWith(u8, line, "air-export-cache "))
        try removeFields(allocator, line, &.{ "status", "duration_ms" })
    else if (std.mem.startsWith(u8, line, "summary distribution-all-serial-run "))
        try removeFields(allocator, line, &.{ "run_id", "fresh_real_rows" })
    else if (std.mem.startsWith(u8, line, "summary distribution-all-serial "))
        try removeFields(allocator, line, &.{ "run_id", "wall_ms", "starting_free_bytes", "minimum_observed_free_bytes", "final_free_bytes", "observed_peak_bytes" })
    else
        try allocator.dupe(u8, line);
    defer allocator.free(semantic);

    try rejectUnknownVolatileFields(semantic);
    return try normalizePaths(allocator, semantic, repo_path);
}

fn removeFields(
    allocator: std.mem.Allocator,
    line: []const u8,
    field_names: []const []const u8,
) ![]u8 {
    var output: std.ArrayList(u8) = .empty;
    errdefer output.deinit(allocator);
    var tokens = std.mem.tokenizeScalar(u8, line, ' ');
    var first = true;
    var removed_count: usize = 0;
    while (tokens.next()) |token| {
        const separator = std.mem.indexOfScalar(u8, token, '=');
        const name = if (separator) |index| token[0..index] else token;
        var remove = false;
        for (field_names) |field_name| {
            if (std.mem.eql(u8, name, field_name)) {
                remove = true;
                break;
            }
        }
        if (remove) {
            removed_count += 1;
            continue;
        }
        if (!first) try output.append(allocator, ' ');
        try output.appendSlice(allocator, token);
        first = false;
    }
    if (removed_count != field_names.len) return error.MissingDeclaredVolatileField;
    return try output.toOwnedSlice(allocator);
}

fn rejectUnknownVolatileFields(line: []const u8) !void {
    const volatile_markers = [_][]const u8{
        " duration_ms=",
        " elapsed_ms=",
        " wall_ms=",
        " pid=",
        " process_id=",
        " timestamp=",
        " cache_status=",
        " cache_observation=",
        " cache_mode=",
    };
    for (volatile_markers) |marker| {
        if (std.mem.indexOf(u8, line, marker) != null) return error.UnclassifiedVolatileField;
    }
}

fn normalizePaths(
    allocator: std.mem.Allocator,
    line: []const u8,
    repo_path: []const u8,
) ![]u8 {
    var repo_normalized: std.ArrayList(u8) = .empty;
    defer repo_normalized.deinit(allocator);
    var rest = line;
    while (std.mem.indexOf(u8, rest, repo_path)) |index| {
        try repo_normalized.appendSlice(allocator, rest[0..index]);
        try repo_normalized.appendSlice(allocator, "<repo>");
        rest = rest[index + repo_path.len ..];
    }
    try repo_normalized.appendSlice(allocator, rest);
    return normalizeScratchIds(allocator, repo_normalized.items);
}

fn normalizeScratchIds(allocator: std.mem.Allocator, line: []const u8) ![]u8 {
    var output: std.ArrayList(u8) = .empty;
    errdefer output.deinit(allocator);
    var cursor: usize = 0;
    while (std.mem.indexOfPos(u8, line, cursor, "tmp/")) |tmp_start| {
        const component_start = tmp_start + "tmp/".len;
        try output.appendSlice(allocator, line[cursor..component_start]);
        var component_end = component_start;
        while (component_end < line.len and line[component_end] != '/' and
            !std.ascii.isWhitespace(line[component_end])) : (component_end += 1)
        {}
        const component = line[component_start..component_end];
        const suffix_start = if (std.mem.lastIndexOfScalar(u8, component, '_')) |index| index + 1 else component.len;
        if (component_end < line.len and line[component_end] == '/' and
            suffix_start < component.len and allDigits(component[suffix_start..]))
        {
            try output.appendSlice(allocator, component[0..suffix_start]);
            try output.appendSlice(allocator, "<run>");
        } else {
            try output.appendSlice(allocator, component);
        }
        cursor = component_end;
    }
    try output.appendSlice(allocator, line[cursor..]);
    return try output.toOwnedSlice(allocator);
}

fn allDigits(text: []const u8) bool {
    if (text.len == 0) return false;
    for (text) |byte| {
        if (!std.ascii.isDigit(byte)) return false;
    }
    return true;
}

fn validateStructure(allocator: std.mem.Allocator, records: []const []const u8) !usize {
    var seen_ids: std.ArrayList([]const u8) = .empty;
    defer seen_ids.deinit(allocator);
    var active_id: ?[]const u8 = null;
    var saw_start = false;
    var completed_gates: usize = 0;
    var inventory_count: ?usize = null;
    var success_count: usize = 0;

    for (records, 0..) |record, record_index| {
        if (std.mem.startsWith(u8, record, "gate-input ")) {
            if (active_id != null) return error.OverlappingGateLifecycle;
            const id = fieldValue(record, "id") orelse return error.MissingGateId;
            for (seen_ids.items) |seen_id| {
                if (std.mem.eql(u8, id, seen_id)) return error.DuplicateGateId;
            }
            try seen_ids.append(allocator, id);
            active_id = id;
            saw_start = false;
        } else if (std.mem.startsWith(u8, record, "gate-start ")) {
            const id = fieldValue(record, "id") orelse return error.MissingGateId;
            const expected_id = active_id orelse return error.GateStartWithoutInput;
            if (saw_start or !std.mem.eql(u8, id, expected_id)) return error.GateLifecycleMismatch;
            saw_start = true;
        } else if (std.mem.startsWith(u8, record, "gate-end ")) {
            const id = fieldValue(record, "id") orelse return error.MissingGateId;
            const expected_id = active_id orelse return error.GateEndWithoutInput;
            if (!saw_start or !std.mem.eql(u8, id, expected_id)) return error.GateLifecycleMismatch;
            const exit_status = fieldValue(record, "exit_status") orelse return error.MissingChildExitStatus;
            if (!std.mem.eql(u8, exit_status, "0")) return error.ChildGateFailed;
            active_id = null;
            saw_start = false;
            completed_gates += 1;
        } else if (std.mem.startsWith(u8, record, "summary distribution-all-gate-inventory ")) {
            if (inventory_count != null) return error.DuplicateGateInventory;
            const subgates = fieldValue(record, "subgates") orelse return error.MissingGateCount;
            inventory_count = try std.fmt.parseInt(usize, subgates, 10);
        } else if (std.mem.eql(u8, record, "ok distribution all gates")) {
            success_count += 1;
            if (record_index + 1 != records.len) return error.SuccessRecordNotLast;
        }
    }
    if (active_id != null) return error.IncompleteGateLifecycle;
    const expected_gates = inventory_count orelse return error.MissingGateInventory;
    if (completed_gates != expected_gates or seen_ids.items.len != expected_gates) {
        return error.GateInventoryMismatch;
    }
    if (success_count != 1) return error.MissingSuccessfulExitRecord;
    return completed_gates;
}

fn fieldValue(line: []const u8, field_name: []const u8) ?[]const u8 {
    var tokens = std.mem.tokenizeScalar(u8, line, ' ');
    while (tokens.next()) |token| {
        const separator = std.mem.indexOfScalar(u8, token, '=') orelse continue;
        if (std.mem.eql(u8, token[0..separator], field_name)) return token[separator + 1 ..];
    }
    return null;
}

fn freeLog(allocator: std.mem.Allocator, log: CanonicalLog) void {
    freeRecords(allocator, log.records);
}

fn freeRecords(allocator: std.mem.Allocator, records: []const []u8) void {
    for (records) |record| allocator.free(record);
    allocator.free(records);
}

test "canonical records remove only declared timing and cache observations" {
    const allocator = std.testing.allocator;
    const end = (try canonicalRecord(
        allocator,
        "gate-end id=x tool=x exit_status=0 duration_ms=12 cache_status=hit",
        "/repo",
    )).?;
    defer allocator.free(end);
    try std.testing.expectEqualStrings("gate-end id=x tool=x exit_status=0", end);
    try std.testing.expect((try canonicalRecord(
        allocator,
        "summary distribution-all-timing subgates=17 total_duration_ms=1",
        "/repo",
    )) == null);
    const cache = (try canonicalRecord(
        allocator,
        "air-export-cache mode=ReleaseFast status=hit duration_ms=12 cache_key=abc descriptor_bytes=4",
        "/repo",
    )).?;
    defer allocator.free(cache);
    try std.testing.expectEqualStrings(
        "air-export-cache mode=ReleaseFast cache_key=abc descriptor_bytes=4",
        cache,
    );
}

test "canonical records normalize repository and scratch run paths" {
    const allocator = std.testing.allocator;
    const record = (try canonicalRecord(
        allocator,
        "summary output=/repo/tmp/vector_gate_1234/object.o local_fail=0",
        "/repo",
    )).?;
    defer allocator.free(record);
    try std.testing.expectEqualStrings(
        "summary output=<repo>/tmp/vector_gate_<run>/object.o local_fail=0",
        record,
    );
}

test "canonical records reject unclassified volatility" {
    try std.testing.expectError(
        error.UnclassifiedVolatileField,
        canonicalRecord(std.testing.allocator, "summary gate pid=12 local_fail=0", "/repo"),
    );
}

test "structure validation requires complete unique gate lifecycles" {
    const records = [_][]const u8{
        "distribution all gates target=x86_64-unknown-linux-gnu",
        "gate-input id=one tool=one target=x runner=zig-run input_scope=runner-command cache_contract=unreported",
        "gate-start id=one tool=one",
        "ok child one",
        "gate-end id=one tool=one exit_status=0",
        "summary distribution-all-gate-inventory schema_version=1 subgates=1 local_fail=0",
        "ok distribution all gates",
    };
    try std.testing.expectEqual(@as(usize, 1), try validateStructure(std.testing.allocator, &records));

    const incomplete = [_][]const u8{
        "gate-input id=one tool=one",
        "gate-start id=one tool=one",
        "summary distribution-all-gate-inventory schema_version=1 subgates=1 local_fail=0",
        "ok distribution all gates",
    };
    try std.testing.expectError(
        error.IncompleteGateLifecycle,
        validateStructure(std.testing.allocator, &incomplete),
    );
}

test "serial normalization removes run observations but retains semantic counters" {
    const allocator = std.testing.allocator;
    const first = (try canonicalRecord(allocator, "summary distribution-all-serial schema_version=1 run_id=abc scratch_path=tmp/same bundle_path=tmp/same/b target=x86_64 mode=serial real_rows_concurrency=1 subgates=17 wall_ms=100 starting_free_bytes=90 minimum_observed_free_bytes=80 final_free_bytes=85 observed_peak_bytes=10 reserve_bytes=50 required_start_bytes=60 local_fail=0", "/repo")).?;
    defer allocator.free(first);
    const second = (try canonicalRecord(allocator, "summary distribution-all-serial schema_version=1 run_id=def scratch_path=tmp/same bundle_path=tmp/same/b target=x86_64 mode=serial real_rows_concurrency=1 subgates=17 wall_ms=20 starting_free_bytes=85 minimum_observed_free_bytes=75 final_free_bytes=80 observed_peak_bytes=10 reserve_bytes=50 required_start_bytes=60 local_fail=0", "/repo")).?;
    defer allocator.free(second);
    try std.testing.expectEqualStrings(first, second);
    try std.testing.expect(std.mem.indexOf(u8, first, "subgates=17") != null);
    try std.testing.expect(std.mem.indexOf(u8, first, "local_fail=0") != null);
    try std.testing.expectError(error.RealRowsParallelEvidenceSchemaMismatch, canonicalRecord(allocator, "real-rows-mode-parallel schema_version=1 normalization_schema=1", "/repo"));
}
