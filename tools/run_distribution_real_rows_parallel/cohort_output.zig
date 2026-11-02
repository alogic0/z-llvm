const std = @import("std");

pub const CacheMode = enum { fresh, require_hit };

const denominator_sha256 = "847e014b2abab0800d0df690ef324dc5fa01299dcf60645b4dc55ca406fe2a31";

const Member = struct {
    function: []const u8,
    result: []const u8,
    witness: []const u8,
    observations: []const u8 = "1",
};

const members = [_]Member{
    .{ .function = "link.MachO.CodeSignature.Signature.size", .result = "8", .witness = "31" },
    .{ .function = "link.MachO.CodeSignature.Signature.slotType", .result = "65536", .witness = "196615" },
    .{ .function = "link.MachO.CodeSignature.Requirements.size", .result = "12", .witness = "43" },
    .{ .function = "link.MachO.CodeSignature.Requirements.slotType", .result = "2", .witness = "13" },
    .{ .function = "ascii.isAscii", .result = "128", .witness = "8256", .observations = "256" },
};

pub fn validate(output: []const u8, mode: []const u8, cache_mode: CacheMode) !void {
    if (!containsWord("ReleaseFast ReleaseSafe ReleaseSmall", mode)) return error.RealRowsOutputUnsupportedMode;
    var header_count: usize = 0;
    var cache_count: usize = 0;
    var cohort_row_count: usize = 0;
    var cohort_seen: [members.len]bool = @splat(false);
    var summary_count: usize = 0;
    var lines = std.mem.splitScalar(u8, output, '\n');
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        if (std.mem.startsWith(u8, line, "distribution-real-rows ")) {
            try checkFields(line, "distribution-real-rows ", "selector_version candidate_file candidate_file_hash limit strict");
            header_count += 1;
            if (!std.mem.eql(u8, fieldValue(line, "candidate_file_hash=") orelse return error.RealRowsOutputMissingDenominator, denominator_sha256) or
                !std.mem.eql(u8, fieldValue(line, "limit=") orelse return error.RealRowsOutputCounterMismatch, "100") or
                !std.mem.eql(u8, fieldValue(line, "strict=") orelse return error.RealRowsOutputCounterMismatch, "true"))
            {
                return error.RealRowsOutputDenominatorMismatch;
            }
            continue;
        }
        if (std.mem.startsWith(u8, line, "air-export-cache ")) {
            try checkFields(line, "air-export-cache ", "mode status duration_ms cache_key descriptor_bytes");
            cache_count += 1;
            if (!std.mem.eql(u8, fieldValue(line, "mode=") orelse return error.RealRowsOutputMissingCacheMode, mode)) {
                return error.RealRowsOutputCacheModeMismatch;
            }
            const expected_status: []const u8 = if (cache_mode == .fresh) "fresh-export" else "hit";
            if (!std.mem.eql(u8, fieldValue(line, "status=") orelse return error.RealRowsOutputMissingCacheStatus, expected_status)) {
                return error.RealRowsOutputCacheStatusMismatch;
            }
            continue;
        }
        if (std.mem.startsWith(u8, line, "execution-cohort-row ")) {
            try checkFields(line, "execution-cohort-row ", "schema mode source function descriptor_sha256 object_bytes object_sha256 reference_bytes reference_sha256 linked_bytes linked_sha256 result witness observations result_sha256 reference_status linked_status real_executed real_programs_ok");
            cohort_row_count += 1;
            if (!std.mem.eql(u8, fieldValue(line, "mode=") orelse return error.RealRowsOutputCohortModeMismatch, mode)) {
                return error.RealRowsOutputCohortModeMismatch;
            }
            if (!std.mem.eql(u8, fieldValue(line, "schema=") orelse return error.RealRowsOutputCohortUnauthenticated, "distribution-execution-cohort-v3") or
                !std.mem.eql(u8, fieldValue(line, "source=") orelse return error.RealRowsOutputCohortUnauthenticated, "../ziglang/src/main.zig") or
                !std.mem.eql(u8, fieldValue(line, "reference_status=") orelse return error.RealRowsOutputCohortUnauthenticated, "0") or
                !std.mem.eql(u8, fieldValue(line, "linked_status=") orelse return error.RealRowsOutputCohortUnauthenticated, "0") or
                !std.mem.eql(u8, fieldValue(line, "real_executed=") orelse return error.RealRowsOutputCohortUnauthenticated, "1") or
                !std.mem.eql(u8, fieldValue(line, "real_programs_ok=") orelse return error.RealRowsOutputCohortUnauthenticated, "1"))
            {
                return error.RealRowsOutputCohortUnauthenticated;
            }
            const function = fieldValue(line, "function=") orelse return error.RealRowsOutputCohortUnauthenticated;
            var matched = false;
            for (members, 0..) |member, index| {
                if (!std.mem.eql(u8, function, member.function)) continue;
                if (cohort_seen[index]) return error.RealRowsOutputCohortDuplicate;
                if (!std.mem.eql(u8, fieldValue(line, "result=") orelse return error.RealRowsOutputCohortUnauthenticated, member.result) or
                    !std.mem.eql(u8, fieldValue(line, "witness=") orelse return error.RealRowsOutputCohortUnauthenticated, member.witness) or
                    !std.mem.eql(u8, fieldValue(line, "observations=") orelse return error.RealRowsOutputCohortUnauthenticated, member.observations))
                {
                    return error.RealRowsOutputCohortUnauthenticated;
                }
                cohort_seen[index] = true;
                matched = true;
            }
            if (!matched) return error.RealRowsOutputCohortUnauthenticated;
            continue;
        }
        if (std.mem.startsWith(u8, line, "summary distribution-real-rows ")) {
            try checkFields(line, "summary distribution-real-rows ", "counter_schema mode selector_version candidate_file_hash limit candidate_rows real_functions_lowered real_objects_emitted real_native_linked real_executed real_programs_ok first_failing_real_row first_failing_stage local_fail");
            summary_count += 1;
            if (!std.mem.eql(u8, fieldValue(line, "mode=") orelse return error.RealRowsOutputMissingSummaryMode, mode)) {
                return error.RealRowsOutputSummaryModeMismatch;
            }
            const required = [_][]const u8{
                "counter_schema=distribution-real-rows-v2",   "limit=100",                  "candidate_rows=100",
                "candidate_file_hash=" ++ denominator_sha256, "real_functions_lowered=100", "real_objects_emitted=100",
                "real_native_linked=100",                     "real_executed=5",            "real_programs_ok=5",
                "first_failing_real_row=-",                   "first_failing_stage=-",      "local_fail=0",
            };
            for (required) |field| {
                const equals = std.mem.indexOfScalar(u8, field, '=').?;
                const actual = fieldValue(line, field[0 .. equals + 1]) orelse return error.RealRowsOutputCounterMismatch;
                if (!std.mem.eql(u8, actual, field[equals + 1 ..])) return error.RealRowsOutputCounterMismatch;
            }
            continue;
        }
        return error.RealRowsOutputUnexpectedRecord;
    }
    if (header_count != 1 or cache_count != 1 or cohort_row_count != members.len or summary_count != 1) {
        return error.RealRowsOutputTopologyMismatch;
    }
    for (cohort_seen) |seen| if (!seen) return error.RealRowsOutputCohortMissing;
}

fn fieldValue(line: []const u8, prefix: []const u8) ?[]const u8 {
    std.debug.assert(std.mem.endsWith(u8, prefix, "="));
    var fields = std.mem.splitScalar(u8, line, ' ');
    while (fields.next()) |field| {
        if (std.mem.startsWith(u8, field, prefix)) return field[prefix.len..];
    }
    return null;
}

fn containsWord(words: []const u8, word: []const u8) bool {
    var iterator = std.mem.splitScalar(u8, words, ' ');
    while (iterator.next()) |item| if (std.mem.eql(u8, item, word)) return true;
    return false;
}

fn checkFields(line: []const u8, record_prefix: []const u8, allowed: []const u8) !void {
    const body = line[record_prefix.len..];
    var fields = std.mem.splitScalar(u8, body, ' ');
    var count: usize = 0;
    while (fields.next()) |field| {
        const equals = std.mem.indexOfScalar(u8, field, '=') orelse return error.RealRowsOutputInvalidField;
        const key = field[0..equals];
        const value = field[equals + 1 ..];
        if (!containsWord(allowed, key)) return error.RealRowsOutputUnknownField;
        if (value.len == 0 or std.mem.indexOfAny(u8, value, "\t\r\n=") != null) return error.RealRowsOutputInvalidField;
        var previous = std.mem.splitScalar(u8, body[0 .. @intFromPtr(field.ptr) - @intFromPtr(body.ptr)], ' ');
        while (previous.next()) |prior| {
            if (std.mem.startsWith(u8, prior, field[0 .. equals + 1])) return error.RealRowsOutputDuplicateField;
        }
        if (containsWord("limit candidate_rows real_functions_lowered real_objects_emitted real_native_linked real_executed real_programs_ok local_fail duration_ms descriptor_bytes object_bytes reference_bytes linked_bytes result witness observations reference_status linked_status", key)) {
            if (value.len > 1 and value[0] == '0') return error.RealRowsOutputInvalidField;
            for (value) |c| if (!std.ascii.isDigit(c)) return error.RealRowsOutputInvalidField;
            _ = std.fmt.parseInt(u64, value, 10) catch return error.RealRowsOutputInvalidField;
        }
        if (containsWord("candidate_file_hash cache_key descriptor_sha256 object_sha256 reference_sha256 linked_sha256 result_sha256", key)) {
            if (value.len != 64) return error.RealRowsOutputInvalidHash;
            for (value) |c| if (!std.ascii.isDigit(c) and !(c >= 'a' and c <= 'f')) return error.RealRowsOutputInvalidHash;
        }
        count += 1;
    }
    if (count != std.mem.count(u8, allowed, " ") + 1) return error.RealRowsOutputMissingField;
    if (containsWord(allowed, "selector_version") and !std.mem.eql(u8, fieldValue(line, "selector_version=").?, "real-candidate-selector-v3")) return error.RealRowsOutputDenominatorMismatch;
}

test "summary rejects substring counters duplicate keys and malformed tokens" {
    const allocator = std.testing.allocator;
    for ([_][]const u8{ "ReleaseFast", "ReleaseSafe", "ReleaseSmall" }) |mode| {
        const valid = try syntheticOutputForTest(mode, "hit", allocator);
        defer allocator.free(valid);
        try validate(valid, mode, .require_hit);
        const mutations = [_][2][]const u8{
            .{ "real_functions_lowered=100", "real_functions_lowered=1000" },
            .{ "real_executed=5 real_programs_ok=5", "real_executed=40 real_programs_ok=40" },
            .{ "local_fail=0", "local_fail=01" },
            .{ "local_fail=0", "not_local_fail=0" },
            .{ "local_fail=0", "local_fail=0 local_fail=1" },
            .{ "local_fail=0", "local_fail=0 local_fail=0" },
            .{ "local_fail=0", "local_fail=18446744073709551616" },
            .{ "local_fail=0", "local_fail=0junk" },
            .{ "local_fail=0", "local_fail=+0" },
            .{ "local_fail=0", "" },
            .{ "duration_ms=1", "duration_ms=-1" },
        };
        for (mutations) |pair| {
            const bad = try std.mem.replaceOwned(u8, allocator, valid, pair[0], pair[1]);
            defer allocator.free(bad);
            if (validate(bad, mode, .require_hit)) |_| return error.InvalidOutputAccepted else |_| {}
        }
    }
}

test "field lookup matches a complete key and parser rejects malformed hashes" {
    try std.testing.expect(fieldValue("not_local_fail=0", "local_fail=") == null);
    try std.testing.expectEqualStrings("1", fieldValue("not_local_fail=0 local_fail=1", "local_fail=").?);
    const valid = try syntheticOutputForTest("ReleaseFast", "hit", std.testing.allocator);
    defer std.testing.allocator.free(valid);
    const bad = try std.mem.replaceOwned(u8, std.testing.allocator, valid, "descriptor_sha256=", "descriptor_sha256=x");
    defer std.testing.allocator.free(bad);
    try std.testing.expectError(error.RealRowsOutputInvalidHash, validate(bad, "ReleaseFast", .require_hit));
}

pub fn syntheticOutputForTest(mode: []const u8, cache_status: []const u8, allocator: std.mem.Allocator) ![]u8 {
    var output = std.Io.Writer.Allocating.init(allocator);
    defer output.deinit();
    const writer = &output.writer;
    const hash = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
    try writer.print("distribution-real-rows selector_version=real-candidate-selector-v3 candidate_file=docs/evidence/real_candidates_release_v3.tsv candidate_file_hash={s} limit=100 strict=true\n" ++
        "air-export-cache mode={s} status={s} duration_ms=1 cache_key={s} descriptor_bytes=1\n", .{ denominator_sha256, mode, cache_status, hash });
    for (members) |member| {
        try writer.print("execution-cohort-row schema=distribution-execution-cohort-v3 mode={s} source=../ziglang/src/main.zig function={s} descriptor_sha256={s} object_bytes=1 object_sha256={s} reference_bytes=1 reference_sha256={s} linked_bytes=1 linked_sha256={s} result={s} witness={s} observations={s} result_sha256={s} reference_status=0 linked_status=0 real_executed=1 real_programs_ok=1\n", .{ mode, member.function, hash, hash, hash, hash, member.result, member.witness, member.observations, hash });
    }
    try writer.print("summary distribution-real-rows counter_schema=distribution-real-rows-v2 mode={s} selector_version=real-candidate-selector-v3 candidate_file_hash={s} limit=100 candidate_rows=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 real_executed=5 real_programs_ok=5 first_failing_real_row=- first_failing_stage=- local_fail=0\n", .{ mode, denominator_sha256 });
    return output.toOwnedSlice();
}

test "five-member cohort output is exact and fails closed on drift" {
    const allocator = std.testing.allocator;
    const valid = try syntheticOutputForTest("ReleaseFast", "hit", allocator);
    defer allocator.free(valid);
    try validate(valid, "ReleaseFast", .require_hit);
    const fresh = try syntheticOutputForTest("ReleaseFast", "fresh-export", allocator);
    defer allocator.free(fresh);
    try validate(fresh, "ReleaseFast", .fresh);
    try std.testing.expectError(error.RealRowsOutputCacheStatusMismatch, validate(fresh, "ReleaseFast", .require_hit));

    const partial = try std.mem.replaceOwned(u8, allocator, valid, "real_executed=5 real_programs_ok=5", "real_executed=3 real_programs_ok=3");
    defer allocator.free(partial);
    try std.testing.expectError(error.RealRowsOutputCounterMismatch, validate(partial, "ReleaseFast", .require_hit));
    const wrong_mode = try std.mem.replaceOwned(u8, allocator, valid, "mode=ReleaseFast source=", "mode=ReleaseSafe source=");
    defer allocator.free(wrong_mode);
    try std.testing.expectError(error.RealRowsOutputCohortModeMismatch, validate(wrong_mode, "ReleaseFast", .require_hit));
    const wrong_denominator = try std.mem.replaceOwned(u8, allocator, valid, denominator_sha256, "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa");
    defer allocator.free(wrong_denominator);
    try std.testing.expectError(error.RealRowsOutputDenominatorMismatch, validate(wrong_denominator, "ReleaseFast", .require_hit));
    const duplicate = try std.mem.replaceOwned(u8, allocator, valid, "link.MachO.CodeSignature.Requirements.size", "link.MachO.CodeSignature.Signature.size");
    defer allocator.free(duplicate);
    try std.testing.expectError(error.RealRowsOutputCohortDuplicate, validate(duplicate, "ReleaseFast", .require_hit));
    const semantic_drift = try std.mem.replaceOwned(u8, allocator, valid, "result=12 witness=43", "result=18 witness=61");
    defer allocator.free(semantic_drift);
    try std.testing.expectError(error.RealRowsOutputCohortUnauthenticated, validate(semantic_drift, "ReleaseFast", .require_hit));
    const slot_type_drift = try std.mem.replaceOwned(
        u8,
        allocator,
        valid,
        "result=2 witness=13",
        "result=12 witness=43",
    );
    defer allocator.free(slot_type_drift);
    try std.testing.expectError(
        error.RealRowsOutputCohortUnauthenticated,
        validate(slot_type_drift, "ReleaseFast", .require_hit),
    );
    const partial_ascii = try std.mem.replaceOwned(u8, allocator, valid, "observations=256", "observations=255");
    defer allocator.free(partial_ascii);
    try std.testing.expectError(error.RealRowsOutputCohortUnauthenticated, validate(partial_ascii, "ReleaseFast", .require_hit));
}
