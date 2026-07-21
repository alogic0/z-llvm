const std = @import("std");
const contract = @import("../o2_compiler_rt_v1_baseline_validation.zig");

pub const ParsedCoverageChannel = struct {
    families: contract.FamilyPair,
    unexpected_family_events: u64,
    argument_index_overflow_events: u64,
};

pub const FunctionRow = struct { name: []const u8, value: u64, size: u64 };

fn parseUnsigned(field: []const u8) !u64 {
    if (field.len == 0) return error.MalformedCounterChannel;
    return std.fmt.parseUnsigned(u64, field, 10) catch error.MalformedCounterChannel;
}

pub fn parseCoverageChannel(bytes: []const u8) !ParsedCoverageChannel {
    var summaries = [_]?contract.FamilyCounters{ null, null };
    var positions_seen = [_][6]bool{[_]bool{false} ** 6} ** 2;
    var schema_count: usize = 0;
    var summary_header_seen = false;
    var position_header_seen = false;
    var unexpected: ?u64 = null;
    var overflow: ?u64 = null;
    var lines = std.mem.splitScalar(u8, bytes, '\n');
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        var fields_iterator = std.mem.splitScalar(u8, line, '\t');
        var fields: [8][]const u8 = undefined;
        var field_count: usize = 0;
        while (fields_iterator.next()) |field| {
            if (field_count == fields.len) return error.MalformedCounterChannel;
            fields[field_count] = field;
            field_count += 1;
        }
        if (std.mem.eql(u8, fields[0], "schema")) {
            if (field_count != 2 or !std.mem.eql(u8, fields[1], "o2_calls_crt_v1_coverage_v1"))
                return error.MalformedCounterChannel;
            schema_count += 1;
            continue;
        }
        if (std.mem.eql(u8, fields[0], "unexpected_family_events")) {
            if (field_count != 2 or unexpected != null) return error.MalformedCounterChannel;
            unexpected = try parseUnsigned(fields[1]);
            continue;
        }
        if (std.mem.eql(u8, fields[0], "argument_index_overflow_events")) {
            if (field_count != 2 or overflow != null) return error.MalformedCounterChannel;
            overflow = try parseUnsigned(fields[1]);
            continue;
        }
        if (std.mem.eql(u8, fields[0], "family")) {
            if (field_count == 8) {
                if (summary_header_seen or position_header_seen or
                    !std.mem.eql(u8, fields[1], "transactions") or
                    !std.mem.eql(u8, fields[2], "requests_registered") or
                    !std.mem.eql(u8, fields[3], "actions_attached") or
                    !std.mem.eql(u8, fields[4], "arguments_staged") or
                    !std.mem.eql(u8, fields[5], "materializations_completed") or
                    !std.mem.eql(u8, fields[6], "actions_completed") or
                    !std.mem.eql(u8, fields[7], "commits")) return error.MalformedCounterChannel;
                summary_header_seen = true;
            } else if (field_count == 4) {
                if (!summary_header_seen or position_header_seen or summaries[0] == null or
                    summaries[1] == null or !std.mem.eql(u8, fields[1], "position") or
                    !std.mem.eql(u8, fields[2], "requests_registered") or
                    !std.mem.eql(u8, fields[3], "arguments_staged")) return error.MalformedCounterChannel;
                position_header_seen = true;
            } else return error.MalformedCounterChannel;
            continue;
        }
        const family_index: usize = if (std.mem.eql(u8, fields[0], "direct_call")) 0 else if (std.mem.eql(u8, fields[0], "int_byte_size_call")) 1 else return error.MalformedCounterChannel;
        if (field_count == 8) {
            if (!summary_header_seen or position_header_seen or summaries[family_index] != null)
                return error.MalformedCounterChannel;
            summaries[family_index] = .{
                .transactions = try parseUnsigned(fields[1]),
                .requests = try parseUnsigned(fields[2]),
                .attachments = try parseUnsigned(fields[3]),
                .stages = try parseUnsigned(fields[4]),
                .materializations = try parseUnsigned(fields[5]),
                .actions = try parseUnsigned(fields[6]),
                .commits = try parseUnsigned(fields[7]),
                .position_requests = [_]u64{0} ** 6,
                .position_stages = [_]u64{0} ** 6,
            };
        } else if (field_count == 4) {
            const position_value = try parseUnsigned(fields[1]);
            if (position_value >= 6 or positions_seen[family_index][position_value]) return error.MalformedCounterChannel;
            if (!position_header_seen or summaries[family_index] == null) return error.MalformedCounterChannel;
            const position: usize = @intCast(position_value);
            positions_seen[family_index][position] = true;
            summaries[family_index].?.position_requests[position] = try parseUnsigned(fields[2]);
            summaries[family_index].?.position_stages[position] = try parseUnsigned(fields[3]);
        } else return error.MalformedCounterChannel;
    }
    if (schema_count != 1 or !summary_header_seen or !position_header_seen or
        summaries[0] == null or summaries[1] == null or unexpected == null or overflow == null)
        return error.MalformedCounterChannel;
    for (positions_seen) |family_positions| for (family_positions) |seen| if (!seen)
        return error.MalformedCounterChannel;
    return .{
        .families = .{ .direct_call = summaries[0].?, .int_byte_size_call = summaries[1].? },
        .unexpected_family_events = unexpected.?,
        .argument_index_overflow_events = overflow.?,
    };
}

fn lessFunction(_: void, left: FunctionRow, right: FunctionRow) bool {
    return std.mem.order(u8, left.name, right.name) == .lt;
}

pub fn parseReadelfFunctions(allocator: std.mem.Allocator, bytes: []const u8, expected_functions: []const []const u8) ![]const FunctionRow {
    var rows = std.array_list.Managed(FunctionRow).init(allocator);
    errdefer rows.deinit();
    var lines = std.mem.splitScalar(u8, bytes, '\n');
    while (lines.next()) |line| {
        var fields = std.mem.tokenizeAny(u8, line, " \t");
        const number = fields.next() orelse continue;
        if (number.len < 2 or number[number.len - 1] != ':') continue;
        const value = fields.next() orelse return error.ParseFailure;
        const size = fields.next() orelse return error.ParseFailure;
        const kind = fields.next() orelse return error.ParseFailure;
        if (!std.mem.eql(u8, kind, "FUNC")) continue;
        _ = fields.next() orelse return error.ParseFailure;
        _ = fields.next() orelse return error.ParseFailure;
        const section = fields.next() orelse return error.ParseFailure;
        const name = fields.next() orelse return error.ParseFailure;
        if (!std.mem.eql(u8, section, "1")) continue;
        const parsed_size = std.fmt.parseUnsigned(u64, size, 10) catch return error.ParseFailure;
        if (parsed_size == 0) continue;
        var expected = false;
        for (expected_functions) |expected_name| if (std.mem.eql(u8, name, expected_name)) {
            expected = true;
            break;
        };
        if (!expected) continue;
        try rows.append(.{
            .name = name,
            .value = std.fmt.parseUnsigned(u64, value, 16) catch return error.ParseFailure,
            .size = parsed_size,
        });
    }
    if (rows.items.len != expected_functions.len) return error.FunctionCountMismatch;
    std.mem.sort(FunctionRow, rows.items, {}, lessFunction);
    for (rows.items[1..], rows.items[0 .. rows.items.len - 1]) |current, prior| {
        if (std.mem.eql(u8, current.name, prior.name)) return error.ParseFailure;
    }
    return rows.toOwnedSlice();
}

pub fn validateReadelfSections(bytes: []const u8) !void {
    var text_count: usize = 0;
    var lines = std.mem.splitScalar(u8, bytes, '\n');
    while (lines.next()) |line| {
        var fields = std.mem.tokenizeAny(u8, line, " \t");
        while (fields.next()) |field| {
            if (!std.mem.eql(u8, field, ".text")) continue;
            const kind = fields.next() orelse return error.ParseFailure;
            if (!std.mem.eql(u8, kind, "PROGBITS")) return error.ParseFailure;
            text_count += 1;
        }
    }
    if (text_count != 1) return error.ParseFailure;
}

pub fn validateObjdumpFunctions(bytes: []const u8, rows: []const FunctionRow) !void {
    for (rows) |row| {
        var found = false;
        var lines = std.mem.splitScalar(u8, bytes, '\n');
        while (lines.next()) |line| {
            var fields = std.mem.tokenizeAny(u8, line, " \t");
            const address = fields.next() orelse continue;
            if (address.len != 16) continue;
            const label = fields.next() orelse continue;
            if (label.len < 3 or label[0] != '<' or label[label.len - 2] != '>' or label[label.len - 1] != ':') continue;
            const parsed = std.fmt.parseUnsigned(u64, address, 16) catch continue;
            if (parsed != row.value) continue;
            found = true;
            break;
        }
        if (!found) return error.ParseFailure;
    }
}

fn sha256FileRange(io: std.Io, file: std.Io.File, offset: u64, size: u64) !contract.Digest {
    var hasher = std.crypto.hash.sha2.Sha256.init(.{});
    var consumed: u64 = 0;
    var buffer: [64 * 1024]u8 = undefined;
    while (consumed < size) {
        const request: usize = @intCast(@min(size - consumed, buffer.len));
        const count = try file.readPositionalAll(io, buffer[0..request], offset + consumed);
        if (count != request) return error.IncompleteCapture;
        hasher.update(buffer[0..count]);
        consumed += count;
    }
    var digest: contract.Digest = undefined;
    hasher.final(&digest);
    return digest;
}

pub fn encodeFunctionManifest(allocator: std.mem.Allocator, io: std.Io, text_path: []const u8, text_size: u64, rows: []const FunctionRow) ![]u8 {
    var file = try std.Io.Dir.openFileAbsolute(io, text_path, .{ .mode = .read_only, .follow_symlinks = false });
    defer file.close(io);
    var output: std.Io.Writer.Allocating = .init(allocator);
    errdefer output.deinit();
    try output.writer.writeAll("name\tvalue_hex\tbytes\tsha256\n");
    for (rows) |row| {
        const end = std.math.add(u64, row.value, row.size) catch return error.StorageOverflow;
        if (end > text_size) return error.ParseFailure;
        const hex = std.fmt.bytesToHex(try sha256FileRange(io, file, row.value, row.size), .lower);
        try output.writer.print("{s}\t{x}\t{d}\t{s}\n", .{ row.name, row.value, row.size, &hex });
    }
    return output.toOwnedSlice();
}

pub fn validateOwnerManifest(bytes: []const u8, expected_function_count: u16) !void {
    var lines = std.mem.splitScalar(u8, bytes, '\n');
    const header = lines.next() orelse return error.OwnerMismatch;
    if (!std.mem.eql(u8, header, "row_identity\tselection_owner")) return error.OwnerMismatch;
    var count: usize = 0;
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        var fields = std.mem.splitScalar(u8, line, '\t');
        const identity = fields.next() orelse return error.OwnerMismatch;
        const owner = fields.next() orelse return error.OwnerMismatch;
        if (identity.len == 0 or fields.next() != null or
            (!std.mem.eql(u8, owner, "composed_block") and !std.mem.eql(u8, owner, "composed_cfg") and
                !std.mem.eql(u8, owner, "legacy_envelope") and !std.mem.eql(u8, owner, "structural_fallback")))
            return error.OwnerMismatch;
        count += 1;
    }
    if (count != expected_function_count) return error.OwnerMismatch;
}

test "coverage counters are exact and malformed channels reject" {
    const channel =
        "schema\to2_calls_crt_v1_coverage_v1\n" ++
        "family\ttransactions\trequests_registered\tactions_attached\targuments_staged\tmaterializations_completed\tactions_completed\tcommits\n" ++
        "direct_call\t2\t3\t2\t3\t2\t2\t2\nint_byte_size_call\t2\t2\t2\t2\t2\t2\t2\n" ++
        "unexpected_family_events\t0\nargument_index_overflow_events\t0\n" ++
        "family\tposition\trequests_registered\targuments_staged\n" ++
        "direct_call\t0\t2\t2\ndirect_call\t1\t1\t1\ndirect_call\t2\t0\t0\ndirect_call\t3\t0\t0\ndirect_call\t4\t0\t0\ndirect_call\t5\t0\t0\n" ++
        "int_byte_size_call\t0\t2\t2\nint_byte_size_call\t1\t0\t0\nint_byte_size_call\t2\t0\t0\nint_byte_size_call\t3\t0\t0\nint_byte_size_call\t4\t0\t0\nint_byte_size_call\t5\t0\t0\n";
    const parsed = try parseCoverageChannel(channel);
    try std.testing.expectEqual(@as(u64, 3), parsed.families.direct_call.requests);
    try std.testing.expectError(error.MalformedCounterChannel, parseCoverageChannel("schema\twrong\n"));
    try std.testing.expectError(error.MalformedCounterChannel, parseCoverageChannel(channel ++ "schema\to2_calls_crt_v1_coverage_v1\n"));
}

test "readelf and objdump observations bind expected functions" {
    try validateReadelfSections("  [ 1] .text PROGBITS 000000 000040\n");
    const rows = [_]FunctionRow{ .{ .name = "alpha", .value = 0, .size = 1 }, .{ .name = "beta", .value = 1, .size = 1 } };
    const parsed = try parseReadelfFunctions(std.testing.allocator, "0: 0000000000000000 0 NOTYPE LOCAL DEFAULT UND\n" ++
        "1: 0000000000000000 1 FUNC GLOBAL DEFAULT 1 alpha\n" ++
        "2: 0000000000000001 1 FUNC GLOBAL DEFAULT 1 beta\n", &.{ "alpha", "beta" });
    defer std.testing.allocator.free(parsed);
    try validateObjdumpFunctions("0000000000000000 <exported_alpha>:\n0000000000000001 <beta>:\n", &rows);
    try std.testing.expectError(error.ParseFailure, validateObjdumpFunctions("0000000000000000 <alpha>:\n", &rows));
}
