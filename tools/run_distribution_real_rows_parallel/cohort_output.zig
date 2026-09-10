const std = @import("std");

pub const CacheMode = enum { fresh, require_hit };

const denominator_sha256 = "83e81a860bb173c3b8c294153faff7af1f1dea73d1217969d6e87b6c08933d5d";

const Member = struct {
    function: []const u8,
    result: []const u8,
    witness: []const u8,
};

const members = [_]Member{
    .{ .function = "coff.Symbol.sizeOf", .result = "18", .witness = "61" },
    .{ .function = "coff.WeakExternalDefinition.sizeOf", .result = "18", .witness = "61" },
    .{ .function = "link.MachO.CodeSignature.Requirements.size", .result = "12", .witness = "43" },
    .{ .function = "link.MachO.CodeSignature.Requirements.slotType", .result = "2", .witness = "13" },
};

pub fn validate(output: []const u8, mode: []const u8, cache_mode: CacheMode) !void {
    var header_count: usize = 0;
    var cache_count: usize = 0;
    var cohort_row_count: usize = 0;
    var cohort_seen = [_]bool{false} ** members.len;
    var summary_count: usize = 0;
    var lines = std.mem.splitScalar(u8, output, '\n');
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        if (std.mem.startsWith(u8, line, "distribution-real-rows ")) {
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
            cohort_row_count += 1;
            if (!std.mem.eql(u8, fieldValue(line, "mode=") orelse return error.RealRowsOutputCohortModeMismatch, mode)) {
                return error.RealRowsOutputCohortModeMismatch;
            }
            if (!std.mem.eql(u8, fieldValue(line, "schema=") orelse return error.RealRowsOutputCohortUnauthenticated, "distribution-execution-cohort-v1") or
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
                    !std.mem.eql(u8, fieldValue(line, "witness=") orelse return error.RealRowsOutputCohortUnauthenticated, member.witness))
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
            summary_count += 1;
            if (!std.mem.eql(u8, fieldValue(line, "mode=") orelse return error.RealRowsOutputMissingSummaryMode, mode)) {
                return error.RealRowsOutputSummaryModeMismatch;
            }
            const required = [_][]const u8{
                "counter_schema=distribution-real-rows-v2",   "limit=100",                  "candidate_rows=100",
                "candidate_file_hash=" ++ denominator_sha256, "real_functions_lowered=100", "real_objects_emitted=100",
                "real_native_linked=100",                     "real_executed=4",            "real_programs_ok=4",
                "first_failing_real_row=-",                   "first_failing_stage=-",      "local_fail=0",
            };
            for (required) |field| if (std.mem.indexOf(u8, line, field) == null) return error.RealRowsOutputCounterMismatch;
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
    const start = std.mem.indexOf(u8, line, prefix) orelse return null;
    const value_start = start + prefix.len;
    const value_end = std.mem.indexOfScalarPos(u8, line, value_start, ' ') orelse line.len;
    return line[value_start..value_end];
}

pub fn syntheticOutputForTest(mode: []const u8, cache_status: []const u8, allocator: std.mem.Allocator) ![]u8 {
    return std.fmt.allocPrint(
        allocator,
        "distribution-real-rows selector_version=real-candidate-selector-v2 candidate_file=docs/evidence/real_candidates_release_v2.tsv candidate_file_hash={s} limit=100 strict=true\n" ++
            "air-export-cache mode={s} status={s} duration_ms=1 cache_key=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa descriptor_bytes=1\n" ++
            "execution-cohort-row schema=distribution-execution-cohort-v1 mode={s} source=../ziglang/src/main.zig function=coff.Symbol.sizeOf descriptor_sha256=a object_bytes=1 object_sha256=b reference_bytes=1 reference_sha256=c linked_bytes=1 linked_sha256=d result=18 witness=61 result_sha256=e reference_status=0 linked_status=0 real_executed=1 real_programs_ok=1\n" ++
            "execution-cohort-row schema=distribution-execution-cohort-v1 mode={s} source=../ziglang/src/main.zig function=coff.WeakExternalDefinition.sizeOf descriptor_sha256=f object_bytes=1 object_sha256=g reference_bytes=1 reference_sha256=h linked_bytes=1 linked_sha256=i result=18 witness=61 result_sha256=j reference_status=0 linked_status=0 real_executed=1 real_programs_ok=1\n" ++
            "execution-cohort-row schema=distribution-execution-cohort-v1 mode={s} source=../ziglang/src/main.zig function=link.MachO.CodeSignature.Requirements.size descriptor_sha256=k object_bytes=1 object_sha256=l reference_bytes=1 reference_sha256=m linked_bytes=1 linked_sha256=n result=12 witness=43 result_sha256=o reference_status=0 linked_status=0 real_executed=1 real_programs_ok=1\n" ++
            "execution-cohort-row schema=distribution-execution-cohort-v1 mode={s} source=../ziglang/src/main.zig function=link.MachO.CodeSignature.Requirements.slotType descriptor_sha256=p object_bytes=1 object_sha256=q reference_bytes=1 reference_sha256=r linked_bytes=1 linked_sha256=s result=2 witness=13 result_sha256=t reference_status=0 linked_status=0 real_executed=1 real_programs_ok=1\n" ++
            "summary distribution-real-rows counter_schema=distribution-real-rows-v2 mode={s} selector_version=real-candidate-selector-v2 candidate_file_hash={s} limit=100 candidate_rows=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 real_executed=4 real_programs_ok=4 first_failing_real_row=- first_failing_stage=- local_fail=0\n",
        .{ denominator_sha256, mode, cache_status, mode, mode, mode, mode, mode, denominator_sha256 },
    );
}

test "four-member cohort output is exact and fails closed on drift" {
    const allocator = std.testing.allocator;
    const valid = try syntheticOutputForTest("ReleaseFast", "hit", allocator);
    defer allocator.free(valid);
    try validate(valid, "ReleaseFast", .require_hit);
    const fresh = try syntheticOutputForTest("ReleaseFast", "fresh-export", allocator);
    defer allocator.free(fresh);
    try validate(fresh, "ReleaseFast", .fresh);
    try std.testing.expectError(error.RealRowsOutputCacheStatusMismatch, validate(fresh, "ReleaseFast", .require_hit));

    const partial = try std.mem.replaceOwned(u8, allocator, valid, "real_executed=4 real_programs_ok=4", "real_executed=3 real_programs_ok=3");
    defer allocator.free(partial);
    try std.testing.expectError(error.RealRowsOutputCounterMismatch, validate(partial, "ReleaseFast", .require_hit));
    const wrong_mode = try std.mem.replaceOwned(u8, allocator, valid, "mode=ReleaseFast source=", "mode=ReleaseSafe source=");
    defer allocator.free(wrong_mode);
    try std.testing.expectError(error.RealRowsOutputCohortModeMismatch, validate(wrong_mode, "ReleaseFast", .require_hit));
    const wrong_denominator = try std.mem.replaceOwned(u8, allocator, valid, denominator_sha256, "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa");
    defer allocator.free(wrong_denominator);
    try std.testing.expectError(error.RealRowsOutputDenominatorMismatch, validate(wrong_denominator, "ReleaseFast", .require_hit));
    const duplicate = try std.mem.replaceOwned(u8, allocator, valid, "link.MachO.CodeSignature.Requirements.size", "coff.Symbol.sizeOf");
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
}
